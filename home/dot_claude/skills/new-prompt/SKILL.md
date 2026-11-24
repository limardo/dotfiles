---
name: new-prompt
description: Deepens a prompt. Invoked as /new-prompt followed by the text to deepen. Takes the user's text, appends a fixed "deeper version" meta-prompt, and answers the combined prompt (what a top professional would do, rawest material, methods/tools, external validation, then a rewritten prompt). Use whenever the user types /new-prompt or asks to run "new-prompt" on some text.
---

# new-prompt

The user's text is: $ARGUMENTS

(If the line above still shows a literal `$ARGUMENTS` placeholder or is empty, the user's text is whatever they wrote after `/new-prompt` in their message. If there is no text at all, ask them for the prompt to deepen and stop.)

Build the combined prompt by taking the user's text verbatim and appending, after a blank line, exactly this block:

```
I want a deeper version of this task, not a bigger one. Before rewriting it: (1) say what a top professional in this field would do here that I’m not asking for; (2) name the rawest material they would start from instead of what has already been digested for me; (3) name the specific methods and tools they would use; (4) say what, other than you or me, would show the result is right. Then rewrite my prompt to ask for exactly that.
```

Then treat that combined prompt as the user's actual request and answer it fully: points (1)–(4), followed by the rewritten prompt in a code block so it is easy to copy. Do not execute the original task itself — the deliverable is the analysis and the rewritten prompt. Reply in the language of the user's text.
