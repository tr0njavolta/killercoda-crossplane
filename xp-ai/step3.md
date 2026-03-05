# The Agent Deploys

The agent reads the live API schema from `kubectl explain`, builds a system prompt from it, then uses tool calling so the model decides what to do — not string parsing.

## Look at the Agent

```bash
cat /root/xp-ai/agent.py
```{{exec}}

Two things to notice:
- `get_system_prompt()` calls `kubectl explain app.spec` at startup — the model always knows the current API surface
- The tool loop runs until the model stops calling tools, then returns its natural-language summary

## Deploy an App

```bash
python3 /root/xp-ai/agent.py "deploy an nginx app called web-frontend"
```{{exec}}

The `[tool]` lines show the model's tool calls being executed. The final line is the model's response.

## Ask for Status

```bash
python3 /root/xp-ai/agent.py "what is the status of web-frontend"
```{{exec}}

The model calls `get_status`, receives structured JSON back, and summarises it in natural language.

## Deploy Another

```bash
python3 /root/xp-ai/agent.py "deploy node:20 as api-server"
```{{exec}}

## List Everything

```bash
python3 /root/xp-ai/agent.py "list all deployed apps"
```{{exec}}

## Interactive Mode

For a conversation that retains context across turns, run the agent interactively:

```bash
python3 /root/xp-ai/agent.py
```{{exec}}

Try asking: *"deploy redis:7 as cache"*, then *"what's running?"*, then *"delete cache"*.

Press `Ctrl+C` to exit.

In the next step, you'll see what Crossplane actually built from those single-field API calls.
