# Emergence Rendering Skill (Modular)

The Emergence Rendering Service provides autonomous agents with the ability to generate diagrams, charts, and mathematical visualizations from structured code or natural language prompts.

## 1. Capabilities
*   **Vector Diagramming**: High-quality SVG/PNG generation for Mermaid, D2, and Graphviz.
*   **Self-Refine**: Generate diagrams via natural language `prompt` (Orchestrated by RenderAgent).
*   **Theming**: Support for `light` and `dark` modes.

## 2. Supported Engines
| Engine | Slug | Description | Use Case |
| :--- | :--- | :--- | :--- |
| **Mermaid** | `mermaid` | Markdown-like syntax for charts. | Flowcharts, Sequence, Gantt. |
| **D2** | `d2` | Declarative Diagramming. | Modern architecture diagrams. |
| **Graphviz** | `graphviz` | DOT language. | Complex networks, state machines. |
| **TikZ** | `tikz` | **(Experimental)** LaTeX PGF/TikZ. | High-fidelity scientific figures. |
| **PlantUML** | `plantuml` | **(Experimental)** UML. | Legacy software architecture. |

## 3. Protocol Interface (v1.0.0+)

**Endpoint**: `POST https://api.emergence.science/tools/render`  
**Cost**: 0.01 Credits (10,000 Micro-credits) per successful render.

### Request Payload
```json
{
  "engine": "d2",
  "code": "direction: right\nuser -> server: auth",
  "prompt": "Draw a high-level architecture of an auth flow",
  "format": "png",
  "theme": "dark"
}
```

> [!NOTE]
> **Direct vs. Generative**: 
> - Use `code` for deterministic, repeatable output when the agent already has the diagram source.
> - Use `prompt` to delegate the diagram design to the service's internal Gemini-powered agent.

## 4. Examples for Agents

### A. Providing Direct Code (Deterministic)
**Input**: `{ "engine": "mermaid", "code": "graph TD; A-->B" }`

### B. Providing a Prompt (Generative)
**Input**: `{ "engine": "graphviz", "prompt": "A state machine for a door with states Locked, Unlocked and Open" }`

## 5. Implementation Notes
*   **Caching**: Re-rendering the exact same `code` hash within 24 hours is typically cached but may still incur a small verification fee.
*   **Error Handling**: If the code fails to compile, the service returns a `500` with the `stderr` logs. Use these logs to self-correct and retry.