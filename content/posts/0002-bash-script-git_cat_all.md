---
title: "Prepare Git-Tracked Code for LLMs"
date: 2025-04-29
description: "A simple Bash script to output all Git-tracked text files in a clean format, making it easier to feed coding projects into LLMs."
tags: ["bash", "git", "scripts", "llm"]
cover:
  image: "img/post-0002-cover.jpg"
  hidden: false
showToc: false
---

When working with large language models (LLMs), it’s often useful to feed them the source code of a project for analysis, refactoring, or documentation assistance.

However, simply copying folders is messy — you usually only want the text files that are tracked by Git, displayed cleanly, without non-text files or noise.

To streamline this, I wrote a Bash script that:

- Ensures you are inside a Git repository.
- Lists all Git-tracked files.
- Filters out non-text files.
- Skips empty or unreadable files.
- Prints the content of each file, with a clean header showing the relative path.

Perfect for quickly preparing a project snapshot to paste into an LLM.

Here’s the script:

```bash
#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
# Treat unset variables as an error.
# Pipelines return status of the last command to exit with non-zero status,
# or zero if all commands exit successfully.
set -euo pipefail

# Requires GNU realpath (on macOS: brew install coreutils)

# Check if the current directory is inside a Git work tree
if ! git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
  echo "Error: This script must be run from within a Git repository." >&2
  exit 1
fi

# Function to process each file
process_file() {
    local file="$1"
    # Use realpath to ensure consistent relative paths
    local relative_path
    relative_path="$(realpath --relative-to="." "$file")"

    # Skip if file is not readable or is empty
    if [ ! -r "$file" ] || [ ! -s "$file" ]; then
        return
    fi

    # Use 'file' command to determine the mime type.
    # -b (--brief): Do not prepend filename to output lines.
    # Check if the mime type starts with "text/". If it DOES NOT, skip the file.
    if ! file -b --mime-type "$file" | grep -q '^text/'; then
        return
    fi

    printf "=== File: %s ===\n\n" "$relative_path"
    cat "$file"
    printf "\n\n"
}

# Main script logic
main() {
    while IFS= read -r -d '' file; do
        process_file "$file"
    done < <(git ls-files -z)
}

# Run the main function
main

exit 0
```

---

### Notes

- `realpath` is used for clean relative paths (you may need GNU coreutils on some systems).
- File type detection is based on MIME type, not extensions.
- The script uses strict error handling (`set -euo pipefail`) to avoid partial outputs or silent failures.

---

This tool has made working with LLMs much smoother when I need to expose full project contexts without manual cleanup.

Feel free to adapt it to your own workflow.

