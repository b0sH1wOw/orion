# Orion - AI-Powered Code Completion for Emacs

Orion is an Emacs package that provides AI-assisted code completion, similar to GitHub Copilot or CodeGeeX. It integrates with AI APIs to offer intelligent code suggestions directly in your Emacs buffers.

## Features

- Real-time AI code suggestions
- Support for multiple programming languages
- Customizable AI model integration
- Lightweight Emacs-native implementation

## Installation

### Prerequisites

1. Install the required `request` package:
   ```elisp
   M-x package-install RET request RET
   ```

2. Add the following configuration to your `~/.emacs` file:
   ```elisp
   ;; Add to load-path
   (add-to-list 'load-path "/path/to/orion.el")

   ;; AI API Configuration
   (setq orion-model "your-ai-model-name")      ; e.g., "gpt-4"
   (setq orion-api-url "your-ai-api-url")       ; e.g., "https://api.openai.com/v1/completions"
   (setq orion-api-key "your-ai-api-key")       ; Your API key

   ;; Load Orion
   (require 'orion)
   ```

### Manual Installation

1. Clone or download `orion.el` to your Emacs configuration directory
2. Update the `load-path` in your config as shown above

## Usage

1. Open a code file in Emacs
2. Start Orion:
   ```elisp
   M-x run-orion
   ```
3. To stop the service:
   ```elisp
   M-x stop-orion
   ```

## Configuration

### Key Variables

| Variable         | Description                              | Example Value                          |
|------------------|------------------------------------------|----------------------------------------|
| `orion-model`    | AI model to use                          | "gpt-4", "code-davinci-002"            |
| `orion-api-url`  | Endpoint for the AI API                  | "https://api.openai.com/v1/completions" |
| `orion-api-key`  | Your API key (keep secure!)              | "sk-...abc123"                         |
| `orion-delay`    | Delay before suggestions appear (seconds) | 0.5                                    |

### Security Note

Always keep your API key secure:
- Never commit it to version control
- Consider using environment variables instead of hardcoding:
  ```elisp
  (setq orion-api-key (getenv "ORION_API_KEY"))
  ```

## Troubleshooting

- **No suggestions appearing**: 
  - Verify your API key and URL are correct
  - Check your internet connection
  - Ensure the `request` package is installed

- **Slow performance**:
  - Try increasing `orion-delay`
  - Check your AI API's rate limits
