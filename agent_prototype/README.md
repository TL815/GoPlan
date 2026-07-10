# GoPlan Agent Prototype

This is a standalone Dart project for validating the travel AI agent before
moving it back into the Flutter app.

## Goal

Validate the complete agent flow independently:

1. Accept a user travel request.
2. Build agent context from history, preferences, and current plan state.
3. Call a mock or real LLM adapter.
4. Parse structured output into a `PlanDraft`.
5. Save the conversation/session state.
6. Return a response that the Flutter UI can render later.

## Layer Map

```text
bin/                      Manual smoke-test entry points.
lib/
  goplan_agent_prototype.dart
  src/
    agent_client.dart      Public facade used by app/UI code.
    agent_config.dart      Runtime configuration.
    agent_exception.dart   Shared error type.
    adapters/              LLM provider abstraction and implementations.
    models/                Request/response/context/plan data contracts.
    parsers/               LLM response and plan JSON parsing.
    prompts/               System prompts and output schema instructions.
    repositories/          Persistence interfaces and in-memory stores.
    services/              Agent orchestration and domain services.
    state/                 Runtime session state.
    tools/                 Future external tool interfaces.
test/                      Unit and flow tests for the prototype.
```

## First Milestone

Use the mock adapter to prove this flow:

```text
AgentClient
  -> TravelAgentService
  -> MockLlmAdapter
  -> PlanDraftParser
  -> ConversationRepository
  -> AgentResponse
```
