---
name: discover-wikipedia-rabbit-holes
description: Curate a small, surprising Wikipedia reading list that mixes a user's established interests with adjacent and unfamiliar subjects. Use for daily or recurring Wikipedia recommendations, intellectual rabbit holes, anti-filter-bubble reading, or a themed learning trail with discussion prompts.
---

# Discover Wikipedia Rabbit Holes

Build a compact reading path that rewards curiosity instead of reproducing a popularity list.

## Workflow

1. Infer the user's interests from the current conversation and any preferences they provide. If context is thin, choose a broad mix rather than blocking on questions.
2. Search the live web for candidate Wikipedia articles. Verify that every recommended page exists and use its canonical URL.
3. Select 5–8 articles with this balance:
   - roughly half closely connected to known interests;
   - several adjacent subjects that create useful bridges;
   - at least one genuinely unexpected wildcard.
4. Prefer specific phenomena, obscure events, unusual systems, intellectual history, and concepts with strong explanatory value. Avoid generic hub pages, listicles, breaking news, and several near-duplicates.
5. Briefly explain why each article is worth reading and how it connects to the preceding article or the user's interests.
6. End with one synthesis question that invites discussion or a note in a digital garden.

## Output

Use the user's language. For each item provide the linked article title and a one- or two-sentence hook. Keep the whole digest scannable and do not summarize the complete article in advance.

When asked for a recurring digest, vary subjects across runs using any prior recommendations visible in context. State clearly that the skill can produce the digest but does not itself create a scheduler; use the environment's task or automation mechanism only when the user asks to schedule it.
