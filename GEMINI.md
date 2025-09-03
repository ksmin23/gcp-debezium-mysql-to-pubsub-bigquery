# Gemini CLI Working Guidelines (gcp-datastream-dataflow-analytics)

This guide helps AI-based development tools like Gemini understand and interact with this project effectively. Its primary purpose is to ensure that any modifications maintain the established architectural principles and coding conventions.

## 1. Core Project Philosophy

This project is built entirely with **Terraform** to provision a GCP data pipeline using Infrastructure as Code (IaC). The structure is highly modular to separate concerns and enhance reusability.

-   **`terraform/environments/`**: Contains the entrypoint configurations for each deployment environment (e.g., `dev`). All `terraform` commands should be run from a subdirectory here.
-   **`terraform/modules/`**: Contains reusable infrastructure modules (`network`, `datastream-gcs`, `dataflow-bigquery`), each responsible for a specific part of the architecture.

**Golden Rule**: Code and documentation must always be in sync. Any change to the infrastructure code must be reflected in `README.md` and `PRD.md`, and vice-versa.

## 2. Coding and Style Conventions

### 2.1. For Terraform Code (`terraform/` directory)

-   **Workflow**: All `terraform` commands (`init`, `plan`, `apply`) must be run from within the environment directory (`terraform/environments/dev`).
-   **Formatting**: All `.tf` files **must** be formatted using `terraform fmt -recursive`. Run this command after any code changes.
-   **Naming Conventions**:
    -   **Resources**: `google_resource_type.descriptive_name` (e.g., `google_datastream_stream.mysql_to_gcs_stream`).
    -   **Variables & Outputs**: `snake_case`.
-   **File Organization**: Related resources are grouped into logical modules (`network`, `datastream-gcs`, etc.).

### 2.2. Git Commit Message Conventions

Follow these seven rules for creating a great Git commit message.

1.  **Separate subject from body with a blank line.**
2.  **Limit the subject line to 50 characters.**
3.  **Capitalize the subject line.**
4.  **Do not end the subject line with a period.**
5.  **Use the imperative mood in the subject line.** (e.g., "Add feature" not "Added feature")
6.  **Wrap the body at 72 characters.**
7.  **Use the body to explain *what* and *why* vs. *how*.**

#### Examples

A good commit message subject line:
```
docs: Add Git commit conventions to GEMINI.md
```

A more detailed commit message with a body:
```
refactor: Rework networking module for clarity

The previous implementation of the networking module was difficult to
understand due to nested conditional logic. This change simplifies the
resource creation process by separating the public and private subnet
configurations.

This improves maintainability and makes it easier to add new
networking features in the future without unintended side effects.
```

## 3. Key Files and Directories

-   **`README.md`**: The primary documentation, including architecture and deployment steps.
-   **`PRD.md`**: The Product Requirements Document, outlining the project's objectives and functional requirements.
-   **`terraform/environments/dev/main.tf`**: The Terraform entrypoint for the `dev` environment.
-   **`terraform/environments/dev/terraform.tfvars`**: The file for environment-specific variable definitions.
-   **`terraform/modules/`**: The directory containing all core, reusable Terraform modules.

## 4. Guide for Making Changes (for AI Assistants)

When asked to modify the project, follow these steps:

1.  **Acknowledge Core Principle**: Always remember that code and documentation must be kept in sync.
2.  **Plan First**: For complex requests, first present a plan that includes a list of files to be modified and the order of operations. Wait for user approval before proceeding.
3.  **Navigate to the Correct Directory**: Before taking any action, change to the relevant environment directory (e.g., `cd terraform/environments/dev`).
4.  **Execute Modification Workflow**:
    -   **If modifying Terraform code (`.tf`):**
        1.  If the module structure is changed (added, deleted, or refactored), the **"Directory Structure"** section in `README.md` **must** be updated.
        2.  If the architecture is changed (e.g., adding new resources), the following files **must** be updated:
            -   The **"Architecture"** section in `README.md`.
            -   The **"Functional Requirements"** and **"Required Resources"** sections in `PRD.md`.
        3.  After all Terraform code modifications, run `terraform fmt -recursive` to format the code.
        4.  Run `terraform validate` to check for syntax errors.
    -   **If modifying documentation (`.md`):**
        1.  Ensure that the content in `README.md` or `PRD.md` accurately reflects the current Terraform code in the `modules` and `environments` directories.
5.  **Report on Completion**: When the task is complete, provide a clear report listing all modified files. This helps the user easily review the changes.
6.  **Commit Message**: Write a clear commit message, specifying the context, e.g., `feat(terraform): add dataflow module for bigquery processing`.

## 5. AI Assistant Guide: How to Use Library Documentation

When you need to consult official library documentation to fix a bug or write code, you must follow this workflow. This provides more accurate and structured information than a general web search.

**Priority Workflow:**

1.  **Resolve Library ID (`resolve-library-id`):**
    To find the precise Context7-compatible ID for a requested library (e.g., `requests`, `Next.js`), **first** use the `resolve-library-id` tool.

2.  **Get Documentation (`get-library-docs`):**
    Use the ID obtained in the previous step to call the `get-library-docs` tool. If necessary, specify the `topic` parameter to retrieve documentation on a specific subject.

3.  **Modify or Write Code:**
    Based on the official documentation retrieved, modify or write the code as requested by the user.

**Actions to Avoid:**

*   Do not use the `google_web_search` tool for the purpose of finding library documentation.
*   Only use `google_web_search` as an alternative in exceptional cases where the `resolve-library-id` or `get-library-docs` tools fail or cannot find the relevant library.