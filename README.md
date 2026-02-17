---
title: EzG-AI
sdk: docker
emoji: 📊
colorFrom: green
colorTo: blue
sdk_version: "3.13"
app_port: 7860
pinned: false
---

## Deployment

- **Frontend / Final App**: Hosted on Firebase.  
  Link: [https://EzG-AI.web.app/](https://EzG-AI.web.app/)

- **Backend**: Dockerized RAG pipeline on Hugging Face Spaces.  
  Link: [https://huggingface.co/spaces/Adivio824](https://huggingface.co/spaces/Adivio824)

---

# Technical Specification: EzG-AI (MVP)
**An asynchronous, pipeline-oriented RAG system for layout-aware extraction, configurable multi-stage retrieval, and state-managed conversational auditing in regulated ESG contexts.**

---

## Audit-Grade Disclaimer

This system demonstrates layout-aware Retrieval-Augmented Generation (RAG) for **Business Responsibility and Sustainability Reporting (BRSR)** and ESG audit assistance. It is explicitly designed for **Augmented Auditing (Human-in-the-Loop)** workflows and is aligned with:

- **SEBI 2023 FAQs on BRSR**
- **Background Material on Sustainability & BRSR Reporting**, issued by the **Sustainability Reporting Standards Board, ICAI** (a statutory body established by an Act of Parliament)

The system supports **evidence discovery, traceability, and audit preparation**, but it is **not a substitute for professional judgment or statutory assurance**. All outputs require manual verification prior to regulatory or compliance use.

---

## 1. System Architecture & Design Philosophy

The primary objective is to move beyond basic RAG pipelines by emphasizing:

- **Traceability over fluency**: Every factual response must be grounded in retrieved evidence with page-level citations.
- **Configurability over hardcoded logic**: All major behaviors are YAML-driven via `ConfigBox` to ensure reproducibility and auditability.
- **Failure-safe behavior**: The system explicitly states when information is not found, preferring abstention over speculation.

These principles directly reflect SEBI’s emphasis on verifiable disclosures, reproducible audit evidence, and the avoidance of unverifiable claims.

---

## 2. Core Architectural Decisions

### 2.1 Fully Config-Driven Design
Critical behaviors are externalized via YAML, including chunking strategy, retrieval depth (`initial_k`, `final_k`), and model selection. No regulatory-relevant logic is hardcoded, enabling consistent behavior across audit runs.

### 2.2 Asynchronous & Batched Processing
Batching is applied only where it materially improves throughput via **FastAPI `BackgroundTasks`**.

* **Strategically Batched (Offline)**: Ingestion & OCR (parallel processing for 100+ pages), Embedding Generation (chunk-level batching), and Report Generation (non-interactive QA).
* **Non-Batched (Real-Time)**: Conversational Querying and Final Answer Synthesis to prioritize low latency and clear evidence linkage.

### 2.3 Modular Pipeline Separation
Composed of independently testable modules: Ingestion, Retrieval, Report Generation, Conversational Chat, and Semantic Visualization. This allows for upgrading components (e.g., swapping parsers) without cascading code changes.

---

## 3. Ingestion Pipeline: Layout-Aware Extraction

Standard text-only parsing often destroys tables, leading to unreliable ESG metric extraction. 

- **Stage 1 (OCR)**: Uses layout-preserving OCR (**LLMWhisperer**) to retain headings and tables.
- **Stage 2 (Chunking)**: Contextualized splitting into semantically coherent segments.
- **Stage 3 (Metadata)**: Each chunk is tagged with `page_number` and `source` to form a persistent **audit trail**.
- **VectorStore**: Persistent **ChromaDB** using `text-embedding-3-small`.

---

## 4. Retrieval Layer: Multi-Stage Intelligence

- **Stage 1 (Query Processing)**: Optional rewriting of natural language into audit-specific terminology (e.g., “emissions” → “Scope 1/2 CO₂e”). Disabled by default for deterministic runs.
- **Stage 2 (Vector Retrieval)**: Semantic search with configurable breadth.
- **Stage 3 (Reranking)**: Optional LLM-based reranking to prioritize high-fidelity evidence.

---

## 5. Security & Guardrails (Defense-in-Depth)

1.  **Deterministic Screening**: Uses **Aho–Corasick** pattern matching to detect known prompt-injection patterns.
2.  **Semantic Screening**: Local embedding models flag queries similar to known attack vectors.
3.  **Indirect Injection Awareness**: Retrieved document chunks are treated as untrusted input and screened.
4.  **Cost-Efficient Rejection**: Unsafe queries are rejected locally on CPU to avoid unnecessary LLM costs.

---

## 6. Evaluation & Performance Metrics

Evaluated across 150+ complex queries on reports from **Jio Financial Services, Infosys, and the Adani ESG Factbook**.

### Retrieval Performance (Internal)
| Metric | Score |
| :--- | :--- |
| **NDCG@10** | 0.847 |
| **MRR** | 0.823 |
| **Precision@5** | 0.891 |

### LLM-as-a-Judge (1–10 Scale)
| Category | Score |
| :--- | :--- |
| **Faithfulness (Groundedness)** | 9.4 |
| **Answer Relevance** | 9.1 |
| **Citation Accuracy** | 9.8 |

---

## 7. Execution Flow

1.  `POST /audit/ingest` → Returns `run_id`.
2.  `GET /audit/status/{run_id}` → Monitor background processing.
3.  `POST /audit/generate-report/{run_id}` → Produces narrative (`.docx`) and quantitative (`.xlsx`) outputs.
4.  `POST /audit/chat/{run_id}` → Interactive evidence verification with sliding-window memory.

---

## Final Notes
EzG-AI prioritizes **traceability, safety, and configurability over automation hype**. It serves as a credible foundation for regulated AI systems, providing auditors with evidence-backed answers rather than speculation.