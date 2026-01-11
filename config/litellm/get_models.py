import litellm

CACHED_MODELS = [
    "github_copilot/claude-haiku-4.5",
    "github_copilot/claude-opus-4.5",
    "github_copilot/claude-opus-41",
    "github_copilot/claude-sonnet-4",
    "github_copilot/claude-sonnet-4.5",
    "github_copilot/gemini-2.5-pro",
    "github_copilot/gemini-3-pro-preview",
    "github_copilot/gpt-3.5-turbo",
    "github_copilot/gpt-3.5-turbo-0613",
    "github_copilot/gpt-4",
    "github_copilot/gpt-4-0613",
    "github_copilot/gpt-4-o-preview",
    "github_copilot/gpt-4.1",
    "github_copilot/gpt-4.1-2025-04-14",
    "github_copilot/gpt-41-copilot",
    "github_copilot/gpt-4o",
    "github_copilot/gpt-4o-2024-05-13",
    "github_copilot/gpt-4o-2024-08-06",
    "github_copilot/gpt-4o-2024-11-20",
    "github_copilot/gpt-4o-mini",
    "github_copilot/gpt-4o-mini-2024-07-18",
    "github_copilot/gpt-5",
    "github_copilot/gpt-5-mini",
    "github_copilot/gpt-5.1",
    "github_copilot/gpt-5.1-codex-max",
    "github_copilot/gpt-5.2",
    "github_copilot/text-embedding-3-small",
    "github_copilot/text-embedding-3-small-inference",
    "github_copilot/text-embedding-ada-002",
]

# Get the full dictionary of all supported models and their metadata
model_list = litellm.model_cost.keys()

# Filter specifically for GitHub Copilot models
copilot_models = [m for m in model_list if m.startswith("github_copilot/")]
print(copilot_models)
