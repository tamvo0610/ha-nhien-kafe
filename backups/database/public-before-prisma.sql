Usage: dotenv run [--help] [-q|--quiet] [--debug] [--override] [--fast] [-f|--file <paths>] [--] <command> [args...]

Run a command with environment variables from a .env file.
Place dotenv options before the command; all following arguments go to the command.

Options:
  -f, --file <paths>  .env paths, comma-separated or repeated (default: .env)
  -q, --quiet suppress the injected env message
  --debug     enable debug logging
  --override  override existing environment variables
  --fast      use the faster character-scanner parser

Environment variables (DOTENV_CONFIG_* names remain as fallbacks):
  DOTENV_PATH, DOTENV_ENCODING, DOTENV_QUIET,
  DOTENV_DEBUG, DOTENV_OVERRIDE,
  DOTENV_FAST
