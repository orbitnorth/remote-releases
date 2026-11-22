#!/usr/bin/env python3
"""
Antigravity (agy) Headless Google OAuth Login Helper

Spawns `agy` in a real pseudo-terminal (PTY) to handle the interactive Google OAuth login.
1. Launches `agy` in PTY.
2. Selects "1. Google OAuth" from the login menu.
3. Captures the Google OAuth URL and prints: CAPTURED_URL:<url>
4. Reads the authorization code from stdin and submits it to `agy`.
5. Waits for `agy` to complete authentication and exit.
"""

import sys
import os
import pty
import time
import select
import re
import signal

def main():
    # Verify agy exists
    agy_path = None
    for p in ['/usr/local/bin/agy', '/root/.local/bin/agy', os.path.expanduser('~/.local/bin/agy')]:
        if os.path.isfile(p) and os.access(p, os.X_OK):
            agy_path = p
            break
            
    if not agy_path:
        # Search PATH
        for d in os.environ.get('PATH', '').split(':'):
            candidate = os.path.join(d, 'agy')
            if os.path.isfile(candidate) and os.access(candidate, os.X_OK):
                agy_path = candidate
                break

    if not agy_path:
        print("ERROR: agy CLI binary not found in PATH", file=sys.stderr)
        sys.exit(1)

    master, slave = pty.openpty()
    pid = os.fork()

    if pid == 0:
        os.close(master)
        os.setsid()
        os.dup2(slave, 0)
        os.dup2(slave, 1)
        os.dup2(slave, 2)
        os.close(slave)
        
        home = os.environ.get('HOME', os.path.expanduser('~'))
        os.environ['HOME'] = home
        os.environ['PATH'] = f"/usr/local/bin:/usr/bin:/bin:{home}/.local/bin:{os.environ.get('PATH', '')}"
        os.environ['TERM'] = 'xterm-256color'
        
        try:
            import termios, struct, fcntl
            fcntl.ioctl(0, termios.TIOCSWINSZ, struct.pack("HHHH", 100, 240, 0, 0))
        except:
            pass
            
        os.execv(agy_path, ['agy'])
    else:
        os.close(slave)
        buf = ""
        auth_url = None
        
        # Give agy a moment to start and show "Select login method"
        time.sleep(1.2)
        # Select "1. Google OAuth" by pressing Enter
        os.write(master, b"\r\n")
        
        start_time = time.time()
        while time.time() - start_time < 10:
            r, _, _ = select.select([master], [], [], 0.5)
            if r:
                chunk = os.read(master, 4096).decode('utf-8', errors='ignore')
                buf += chunk
                
                # Check for Google OAuth URL
                # Pattern: https://accounts.google.com/o/oauth2/auth?...&state=...
                match = re.search(r'(https://accounts\.google\.com/o/oauth2/auth\?[^\s\x1b"\'<>]+)', buf)
                if match and not auth_url:
                    raw_url = match.group(1).strip()
                    # Clean any trailing prompt text
                    clean_match = re.search(r'(https://accounts\.google\.com/o/oauth2/auth\?.*?&state=[a-zA-Z0-9_\-]+)', raw_url)
                    auth_url = clean_match.group(1) if clean_match else raw_url
                    print("CAPTURED_URL:" + auth_url, flush=True)
                    break

        if not auth_url:
            print("ERROR: Failed to capture OAuth URL. Output was:\n" + buf, file=sys.stderr)
            try:
                os.kill(pid, signal.SIGKILL)
            except:
                pass
            sys.exit(1)

        # Wait for authorization code from standard stdin (line by line)
        line = sys.stdin.readline()
        if not line:
            try:
                os.kill(pid, signal.SIGKILL)
            except:
                pass
            sys.exit(1)

        auth_code = line.strip()
        if not auth_code:
            try:
                os.kill(pid, signal.SIGKILL)
            except:
                pass
            sys.exit(1)

        # Write the authorization code + Enter to agy's PTY
        os.write(master, auth_code.encode('utf-8') + b"\r\n")
        
        # Monitor for completion (up to 15 seconds)
        completion_buf = ""
        done_time = time.time()
        success = False
        
        while time.time() - done_time < 15:
            r, _, _ = select.select([master], [], [], 0.5)
            if r:
                try:
                    c = os.read(master, 4096).decode('utf-8', errors='ignore')
                    if not c:
                        break
                    completion_buf += c
                    low = completion_buf.lower()
                    if "success" in low or "logged in" in low or "welcome" in low or "authenticated" in low:
                        success = True
                        break
                    if "error" in low or "failed" in low or "invalid" in low:
                        break
                except:
                    break
                    
        # Check if process is still alive or exited cleanly
        time.sleep(1)
        print("LOGIN_OUTPUT:\n" + completion_buf, flush=True)
        
        try:
            os.kill(pid, signal.SIGTERM)
        except:
            pass

        if success:
            sys.exit(0)
        else:
            sys.exit(1)

if __name__ == '__main__':
    main()
