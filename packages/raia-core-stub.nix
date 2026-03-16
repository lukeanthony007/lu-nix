#
# Minimal raia-core stub server for boot-path validation.
#
# Serves /health and /health/ready on :4111 so the shell boot path
# can be tested even when the full kernel isn't available.
#
{ pkgs }:

let
  # HTTP response handler as a separate script (avoids nested quoting)
  handler = pkgs.writeShellScript "raia-core-handler" ''
    read REQUEST
    BODY='{"error":"stub"}'
    case "$REQUEST" in
      *"/health/ready"*)
        BODY='{"ready":true,"vault":true,"running":true}'
        ;;
      *"/health"*)
        BODY='{"status":"ok"}'
        ;;
      *"/conversations"*)
        BODY='{"sessions":[]}'
        ;;
    esac
    LEN=''${#BODY}
    printf "HTTP/1.1 200 OK\r\nContent-Type: application/json\r\nContent-Length: %d\r\nConnection: close\r\n\r\n%s" "$LEN" "$BODY"
  '';
in
pkgs.writeShellScriptBin "raia-core-stub" ''
  PORT="''${RAIA_COGNITION_PORT:-4111}"

  echo "raia-core-stub: serving health endpoints on :$PORT"
  echo "  This is a stub for boot-path validation only."
  echo "  Replace with real raia-core for full functionality."

  while true; do
    ${pkgs.socat}/bin/socat TCP-LISTEN:$PORT,reuseaddr,fork EXEC:${handler} 2>/dev/null || {
      echo "raia-core-stub: port $PORT in use, retrying in 2s..."
      sleep 2
    }
  done
''
