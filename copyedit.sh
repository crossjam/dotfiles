#!/usr/bin/env bash

# copyedit - Use LLM to copyedit text from stdin or file
# Usage: copyedit [options] < input.txt
#        copyedit [options] input.txt
#        cat input.txt | copyedit [options]
#
# Options:
#   -h, --help    Show this help message
#   Other args    Passed to llm (e.g., -m gpt-4o, --no-stream)

# Parse arguments
file=""
llm_args=()

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            cat << 'HELP'
copyedit - Copyedit text using LLM

Usage: copyedit [options] < input.txt
       copyedit [options] input.txt
       cat input.txt | copyedit [options]

Options:
  -h, --help           Show this help message
  Other arguments      Passed to llm command (e.g., -m gpt-4o, --no-stream)

Examples:
  copyedit < draft.txt
  copyedit draft.txt
  cat draft.txt | copyedit -m claude-opus
HELP
            exit 0
            ;;
        *)
            # Check if this looks like a file (doesn't start with -)
            if [[ ! $1 =~ ^- ]] && [[ -z "$file" ]]; then
                file="$1"
            else
                llm_args+=("$1")
            fi
            shift
            ;;
    esac
done

# Define the system prompt
read -r -d '' system_prompt <<'EOF'
You are copyeditor that suggests and makes edits on text.

You review the text you receive for punctuation, grammatical,
spelling, and logical errors. Try hard to keep the style and tone but
make corrections as needed. Summarize any corrections you made at the
bottom of the text in bullet point format.

Don't make any commentary at the beginning of your output. Just output
the corrected code to start off. Use a string of '=' characters to
separate corrected text from your comments.

Always, always, always output the document to start. Even if you don't
make any changes. Do not ignore this instruction.

If the text looks like markdown, ignore fenced quotes or leading text with
> . Don't edit the quoted text.

Do not modify emojis.

EOF

# Handle both stdin and file input
{
    echo "Copy edit the text that follows:"
    echo ""
    if [[ -n "$file" ]]; then
	cat "$file"
    else
	cat
    fi
} | llm "${llm_args[@]}" -s "$system_prompt"

