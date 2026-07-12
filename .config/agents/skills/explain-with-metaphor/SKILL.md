---
name: explain-with-metaphor
description: Explain a difficult concept through a concrete, memorable everyday metaphor while preserving the important mechanics and limits of the original. Use when the user asks for an analogy, intuitive explanation, plain-language mental model, comparison between concepts, or help making technical material stick.
---

# Explain With a Metaphor

Turn an abstract mechanism into a familiar scene the user can mentally simulate.

## Workflow

1. Identify the concept's causal skeleton: actors, state, events, dependencies, bottleneck, and observable result.
2. Choose a familiar domain with the same relationships, such as a workplace, kitchen, traffic system, library, delivery service, or household. Prefer domains suggested by the user's background.
3. Map each important element explicitly. Preserve relationships rather than matching superficial appearance.
4. Walk through one concrete scenario in the metaphor before returning to the real concept.
5. State where the metaphor breaks. Never let a vivid analogy silently replace a technically important qualification.
6. If comparing two systems, hold the scene constant and change only the mechanism that differs.

## Quality bar

- Prefer one strong metaphor over several loose analogies.
- Use concrete nouns and actions; avoid explaining one abstraction with another.
- Keep terminology available in parentheses so the user can reconnect intuition to the formal concept.
- Do not infantilize the user or sacrifice correctness for simplicity.
- For safety-critical, legal, medical, or financial topics, label the metaphor as intuition and give the precise rule separately.

## Output

Use the user's language and default to this compact shape:

1. **In one sentence:** the core idea.
2. **Metaphor:** the familiar scene and its moving parts.
3. **Mapping:** what corresponds to what.
4. **Where it breaks:** the main limitation.
5. **Back to reality:** a short technically accurate restatement.
