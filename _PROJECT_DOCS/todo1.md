# Two-Phase Markdown Rendering Implementation Plan

> **Lifecycle: historical implementation plan.** Completed and unchecked items
> below are retained for archaeology, not as the canonical backlog. Start with
> `_PROJECT_DOCS/README.md`, current compiler/renderer source, and the Backlog in
> `AGENTS.md`.

Core Problem: Currently, markdown content and Phoenix components live in separate worlds. Your markdown gets rendered to static HTML, which means you can't embed interactive components (like carousels or image galleries) directly in your content.

YOU WILL FOLLOW TDD PRINCIPLES.
- FIRST ASSESS EXISTING CODE.
- FIGURE OUT WHAT IS NEXT IN THE PLAN.
- YOU WILL WRITE TESTS FOR ALL NEW CODE.
- THEN YOU'lL PASS THE TESTS.
- THEN ASK USER FOR APPROVAL. 
## Requirements

The two-phase markdown rendering system should:

- **Markdown First**: Keep content as close to standard markdown as possible for author friendliness
- **Component Integration**: Allow Phoenix components to be embedded within markdown content
s- **No Duplicate Logic**: Avoid recreating Phoenix/HEEx validation and component logic
- **DX Consistency**: Use existing Phoenix patterns where possible instead of inventing new ones
- **Performance**: Minimize performance impact and enable caching where appropriate
- **Maintainability**: Follow Elixir best practices and keep the codebase maintainable
- **Typography Consistency**: Ensure consistent typography by using Typography components for all text elements
- **Safe Execution**: Prevent security issues like arbitrary code execution
- **Graceful Failures**: Handle unknown components or syntax errors gracefully with helpful error messages
- **Content Compatibility**: Support both existing content and new component-enhanced content
- **Image Handling**: Seamlessly support image-focused components like galleries and carousels
- **Localization Support**: Maintain support for content translations
  - Translations must work with both raw HTML and component AST formats
  - LiveView templates should render translated content properly regardless of format
  - Translation storage should continue to use raw content, not rendered output
  - Ensure all LiveView tests for translations continue to pass with component AST
s
### Guiding Principles

After exploring options, we're adopting the following principles:

1. **Preserve Standard Markdown**: Standard markdown patterns should remain unchanged whenever possible
2. **Transform Common Patterns**: Convert standard markdown elements to components automatically (e.g., images to figure components)
3. **Custom Syntax Sparingly**: Introduce custom syntax only for layouts and interactive elements that cannot be expressed in standard markdown
4. **Progressive Enhancement**: Allow adding metadata to standard markdown elements to enhance them
5. **Frontmatter for Page Structure**: Use frontmatter for overall page structure and layout

### Syntax Approach

We'll use a hybrid approach:

1. **Standard markdown** for most content (paragraphs, headings, lists, etc.)
2. **Auto-transformation** for common patterns:
   - Convert `![alt](src)` to figure components
   - Convert `![alt](src)\n*Caption*` to figure components with captions
   - Transform headings and paragraphs to Typography components (already implemented)

3. **Custom delimiter syntax** only when needed for components with no markdown equivalent:
   ```markdown
   ::carousel{title="Project Images" autoplay=true}
   ![Image 1](image1.jpg)
   *Caption 1*

   ![Image 2](image2.jpg)
   *Caption 2*
   ::end-carousel
   ```

4. **Frontmatter** for page-level layout and structure:
   ```markdown
   ---
   layout: project
   columns:
     - width: 2/3
       content: main
     - width: 1/3
       content: sidebar
   ---
   ```

## Architecture Approach

Based on our analysis, we're adopting a **Pipeline-Oriented Architecture** for the refactoring:

- **Document Flow**: Markdown text → AST → Phoenix Components
- **Pipeline Processing**: Document transformed through ordered stages
- **Clear Transformations**: Each stage has a single, clear responsibility
- **Modular Design**: Components easily registered and interchangeable

For the folder structure, we'll enhance the existing codebase:

```
lib/portfolio/content/
├── markdown/                # Namespace for markdown processing
│   ├── parser.ex            # Parse markdown into initial AST
│   ├── ast.ex               # AST node types and manipulation functions
│   ├── pipeline.ex          # Orchestrates transformation flow
│   ├── transforms/          # Individual transformation steps
│   │   ├── typography.ex    # Text element enhancements
│   │   ├── component.ex     # Component resolution
│   │   └── layout.ex        # Layout processing
│   └── renderer.ex          # Final rendering (components/HTML)
├── components/              # Component system
│   ├── registry.ex          # Component lookup and registration
│   └── definition.ex        # Component behavior and helpers
├── cache.ex                 # Caching services
└── markdown.ex              # Public API facade
```

This approach builds upon the existing modules while improving maintainability and extensibility through a clearer separation of concerns and functional composition.

### Architecture Compatibility Considerations

A key architectural challenge is ensuring the component AST approach works with the translation system:

1. **Translation Storage**: Translations are stored as raw content, not rendered HTML
2. **Rendering Pipeline**: Both original content and translations pass through the same rendering pipeline
3. **Format Expectations**: Parts of the system (like EntryManager's compile_translations) expect rendered content as strings
4. **LiveView Templates**: Templates currently use raw() to render HTML content and need updating for component AST

The architecture must accommodate both formats during the transition period, ensuring that LiveView tests continue to pass while we implement the new component-based approach.

## UPDATED RENDERING APPROACH

After review, we're moving away from HTML caching to focus exclusively on AST caching and LiveView rendering:

1. **AST-Only Caching**: We'll cache only the AST (Abstract Syntax Tree), not pre-rendered HTML
   - The AST is the single source of truth for content representation
   - No redundant HTML caching needed
  
2. **Direct Phoenix Integration**: LiveView will render the AST directly
   - Phoenix LiveView already handles server-side rendering for SEO benefits
   - This approach eliminates duplicate rendering paths

3. **No HTML Backwards Compatibility**: We're simplifying by removing HTML-specific code
   - We can focus on a clean implementation for Phoenix components
   - All existing templates will be updated to work with component AST

This approach streamlines our architecture and eliminates redundant processing, while still meeting SEO requirements through LiveView's server-side rendering capabilities.

## UPDATED TODO!

*   Improve component architecture and organization.
*   Ensure correct markdown to AST rendering pipeline.
*   Follow Test-Driven Development (TDD) principles.
*   Implement functional transformation approach with explicit data flow.
*   Reorganize files according to the new folder structure.

## Current Status (Updated)

*   **Component Architecture:**
    *   [x] New `Portfolio.Content.MarkdownRendering.Components.Definition` module for component definition.
    *   [x] New `Portfolio.Content.Markdown.Component.Registry` (GenServer-based) for component registration and lookup.
    *   [x] Migration of all components to the new `Definition` and Registry.
    *   [ ] Deprecation/removal of the older `component_registry.ex` (ETS-based).
*   **Rendering Pipeline:**
    *   [x] Pipeline stages defined using `Portfolio.Content.MarkdownRendering.Pipeline.Stage` behavior.
    *   [x] Implemented `TypographyEnhancement`, `ComponentResolution`, `LayoutProcessing` stages.
    *   [x] Fixed pipeline option passing issues (BadMapError).
*   **File Reorganization:**
    *   [x] Create new `lib/portfolio/content/markdown/` namespace
    *   [x] Move AST module to `lib/portfolio/content/markdown/ast.ex`
    *   [x] Create transform-based pipeline infrastructure
    *   [ ] Create public API facade in `lib/portfolio/content/markdown.ex`

## Actionable TODO List

**2. Debugging Pipeline Option Passing (High Priority - Fixes `BadMapError` tests)**

*   [x] **Systematically Review Pipeline Stage Calls:**
    *   [x] Implement AST module with proper traversal functionality
    *   [x] Create Pipeline module with processing capabilities
    *   [x] Fix test stage implementations to correctly handle AST nodes
    *   [x] Ensure all tests for the AST and Pipeline modules pass

**3. Component Implementation (Medium Priority)**

*   [x] **Implement `FigureComponent`:**
    *   [x] Create `srv/personal-site/lib/portfolio_web/components/figure.ex` using the `Definition` module.
    *   [x] Define attributes for `FigureComponent` (src, alt, caption, class, etc.).
    *   [x] Figcaption should use the Typography component utilizing the figcaption element.
    *   [x] Implement the rendering logic in `figure/1`.
    *   [x] Write tests for `FigureComponent` (unit tests).
*   [x] **Register New Components:**
    *   [x] Register `figure` components in the new GenServer-based registry (in `Portfolio.Application.register_components` or in the component modules themselves using `register()` callback).

**4. Test Fixes (High Priority - Unblock development)**

*   [x] **Fix `BadMapError` Tests:**  Fixed the option passing issues to resolve the `BadMapError` failures in markdown-related tests.
*   [x] **Fix `__using__ macro provides register function` Test (Test 49):** Update the assertion in `DefinitionTest` to correctly verify component registration (likely by removing `capture_log` and asserting the direct return value or mocking).
*   [ ] **Address Network Errors in `RemoteUpdateTriggerTest` and `GitRepoSyncerTest` (Tests 43-48, 47-48):** Decide on a strategy: run in a network-enabled environment, mock network calls, or skip tests in environments without network access. Implement the chosen strategy.
*   [x] **Fix `using real pipeline stages processes AST through layout processing stage` Test (Test 50):** Correct option passing in the test setup for `LayoutProcessing` stage (similar to point 2).
*   [ ] **Review and Fix "Empty content test expected an error but got success":** Examine the code in `Renderer` and `CustomParser` to ensure empty content is handled correctly and returns an error as expected by the test.
*   [ ] **Address "Column layout components aren't being detected properly":** Debug component registration and resolution in the pipeline. Ensure `ColumnLayout` component is correctly registered and that `ComponentResolution` stage is correctly looking it up.
*   [ ] **Address "Whitespace differences causing text comparison failures":** If whitespace is causing test failures in text comparisons, use more robust comparison methods in tests (e.g., normalize whitespace before comparison, or use regex for flexible matching).

**5. Documentation (Low Priority - but important for long-term maintainability)**

*   [ ] **Document the new Component Architecture:** Update documentation to explain the new component system, the `Definition` module, and the GenServer-based registry.
*   [ ] **Document Pipeline Stages:** Document each pipeline stage, its purpose, options, and how it transforms the AST.


**6. Implement Functional Transformation Approach (High Priority)**

*   [x] **Create Transform-Based Pipeline:**
    *   [x] Create AST module with node traversal and finding functionality
    *   [x] Implement Pipeline module for AST processing through stages
    *   [x] Create component transform module that works with the registry
    *   [x] Add comprehensive tests for each module with all tests passing
*   [ ] **Create Public API Module:**
    *   [ ] Create `lib/portfolio/content/markdown.ex` as the main facade with clean functional API
    *   [ ] Implement core functions for parsing, transforming, and rendering markdown
    *   [ ] Document all public functions with proper typespecs
*   [ ] **Refactor Renderer for Functional Composition:**
    *   [ ] Update renderer to use `with` expressions for composing transforms
    *   [ ] Implement explicit error handling for each transformation step
    *   [ ] Create helper functions for common transformation chains
    *   [ ] Remove HTML-specific code to focus exclusively on AST
    *   [ ] Update all related tests to expect AST-only rendering

**7. File Reorganization (Medium Priority)**

*   [x] **Create New Directory Structure:**
    *   [x] Create structure for AST, Pipeline, and Component Registry modules
    *   [x] Implement transform modules with proper functionality
*   [ ] **Migrate Existing Modules:**
    *   [ ] Create new `parser.ex` based on `custom_parser.ex` with cleaner API
    *   [ ] Implement new `renderer.ex` with functional approach focused on AST
    *   [ ] Remove HTML generation code from renderer.ex
*   [ ] **Update Imports and References:**
    *   [ ] Update all module references in tests
    *   [ ] Fix imports in dependent modules
    *   [ ] Deprecate old modules with warnings before removal

## Phase 1: Research and Design

DO NOT MAKE CAROUSELS OR FIGURE COMPONENTS. ITS OUT OF SCOPE. I'LL BE FIRED IF YOU EVEN SO MUCH AS THINK ABOUT CAROUSELS.

- [x] **Story 1.1**: Evaluate component syntax options
  - Research different syntax approaches (custom delimiters, HTML-like, code blocks)
  - Evaluate each option against our requirements
  - Document pros and cons of each approach
  - Make a final recommendation based on our hybrid approach
  
  **Definition of Done:**
  - Code repository contains prototype implementations of:
    - Auto-transformation of standard markdown images to figure components
    - Custom delimiter syntax for carousel and layout components
    - Frontmatter-driven layout handling
  - Test suite with examples of each approach
  - Documentation of the decision process and final approach
  - CI pipeline validates syntax examples against chosen parser
    - RUn `./run elixir:lint` then `./run elixir:format` to check for linting and formatting errors

- [x] **Story 1.4**: Create component registry design
  - Design module for mapping component names to Phoenix component modules/functions
  - Specify registration interface and lookup functionality
  - Plan for handling unknown components
  - Define component documentation requirements
  - Determine whether to create a separate ComponentRegistry module or integrate into existing modules
  
  **Definition of Done:**
  - Component registry module interface defined in code
  - Working prototype with at least 3 registered components:
    - ✅ Typography component (existing) for headings and text elements
    - ❌ A Figure component for standard markdown images (skipped per requirements)
    - ✅ A ColumnLayout component for multi-column content
  - Tests for successful lookups and error handling
  - Documentation template for component registration
    - RUn `./run elixir:lint` then `./run elixir:format` to check for linting and formatting errors
  - Run `./run elixir:test` to make sure all tests pass.

- [x] **Story 1.5**: Design AST structure
  - Define AST node structure for both markdown elements and components
  - Create mapping from standard markdown elements to Typography component calls
  - Define component node representation for easy transformation
  - Document how component attributes should be derived from markdown and custom syntax
  - Design for extensibility and maintainability
  
  **Definition of Done:**
  - AST structure defined in ast.ex with proper typespecs
  - Clear examples of AST nodes for different element types
  - Docs showing how AST represents different markdown constructs
  - AST designed for pipeline processing pattern
  - Verification with `./run elixir:format`, `./run elixir:lint`, and `./run elixir:test`

## Phase 2: Proof of Concept

- [x] **Story 2.1**: Enhance CustomParser with component support
  - Refactor `custom_parser.ex` to use pipeline architecture
  - Design cleaner component extraction functions
  - Reduce cyclomatic complexity in parsing functions
  - Enhance error reporting
  - Add improved documentation
  
  **Definition of Done:**
  - Refactored parser with reduced complexity
  - Unit tests with increased coverage
  - All verification steps pass:
    - Format: `./run elixir:format` exits with code 0
    - Lint: `./run elixir:lint` shows improved metrics
    - Tests: `./run elixir:test` specific to parser functionality pass
    - Security: No new security issues reported
    - Static Analysis: `./run elixir:dialyzer` reports no errors

- [x] **Story 2.2**: Enhance HTMLCompiler for component rendering
  - Refactor HTMLCompiler to use the pipeline stages approach
  - Implement component resolution stage
  - Add better error handling for component transformation
  - Improve separation of concerns in compiler
  
  **Definition of Done:**
  - Refactored HTMLCompiler with pipeline integration
  - Component resolution moved to dedicated stage module
  - Unit tests for component rendering pipeline
  - All verification steps pass:
    - `./run elixir:format`
    - `./run elixir:lint`
    - `./run elixir:test`
    - `./run elixir:security`
    - `./run elixir:dialyzer`

- [x] **Story 2.3**: Implement Pipeline Architecture
  - Create `pipeline.ex` for orchestration
  - Define pipeline stage behavior in `pipeline/stage.ex`
  - Implement base transformation stages
  - Add composition and flow control for pipeline
  - Ensure proper error handling throughout
  
  **Definition of Done:**
  - Working pipeline architecture with stage composition
  - At least 3 essential transformation stages implemented
  - Tests showing document transformation through pipeline
  - All verification steps pass
  - Documentation of pipeline extension points

- [ ] **Story 2.4**: End-to-end demonstration
  - Connect parser, pipeline, and renderer together
  - Create sample content with both markdown and components
  - Demonstrate parsing to AST and rendering in LiveView
  - Document findings and any adjustments needed
  
  **Definition of Done:**
  - Integration test with full pipeline processing
  - Performance comparison with previous implementation
  - Automated test verifies all components render without errors
  - All verification steps pass through full pipeline
  - Documentation of the complete workflow

## Phase 3: Parser Enhancement

*   [x] **Story 3.1**: Refactor Component Registry
    *   [x] Enhance registry with improved error handling
    *   [x] Add component documentation capabilities
    *   [x] Improve type specifications
    *   [x] Follow behavior-based approach for components
  
    **Definition of Done:**
    *   [x] Refactored registry with cleaner interfaces
    *   [x] Component behavior definition for standardization
    *   [x] Improved error messages for troubleshooting
    *   [x] All verification steps pass with improved metrics
    *   [x] Documentation of component registration process

- [x] **Story 3.2**: Typography mapping implementation
  - Create dedicated typography transformation stage
  - Implement special handling for first paragraph (dropcap)
  - Ensure proper class attribution for typography elements
  - Test with various markdown formatting scenarios
  
  **Definition of Done:**
  - Typography stage properly integrated in pipeline
  - Unit tests for all typography transformations
  - Visual verification of typography styles
  - All verification steps pass

- [x] **Story 3.3**: Create robust component definition system
  - Implement component behavior specification
  - Add attribute validation helpers
  - Create tools for component documentation
  - Add runtime validation of component structure
  
  **Definition of Done:**
  - Component definition behavior implemented
  - Validation tooling for component attributes
  - Documentation generation from component definitions
  - All verification steps pass

## Phase 4: Rendering Pipeline

- [x] **Story 4.1**: Enhance renderer for pipeline integration
  - Update the existing `renderer.ex` to work with pipeline output
  - Define clear interfaces between pipeline and rendering
  - Optimize the caching strategy for processed documents
  - Document the enhanced architecture
  
  **Definition of Done:**
  - Updated Renderer module with pipeline integration
  - Interface functions have property-based test coverage
  - Caching functions pass performance threshold tests
  - All verification steps pass:
    - `./run elixir:format`
    - `./run elixir:lint` 
    - `./run elixir:test`
    - `./run elixir:security`
    - `./run elixir:dialyzer`

- [ ] **Story 4.2**: Implement AST caching mechanism
  - Create storage for pipeline-processed ASTs
  - Implement cache invalidation strategy
  - Add performance metrics for cache effectiveness
  - Test caching with various content scenarios
  - Remove HTML caching in favor of AST-only approach
  
  **Definition of Done:**
  - AST-focused caching implemented with measurable benefits
  - Cache hit ratio measurement in test environment
  - Performance tests with and without caching
  - HTML generation code removed from renderer
  - All verification steps pass


## Phase 5: Content System Integration

- [ ] **Story 5.1**: Extend content schemas for AST storage
  - Add field for storing parsed AST representation
  - Update migrations for new schema
  - Add validation for AST field
    - RUn `./run elixir:lint` then `./run elixir:format` to check for linting and formatting errors
  - Run `./run elixir:test` to make sure all tests pass.
  - Analyze if custom_parser.ex and html_compiler.ex are still used in the codebase
    - **Architectural insight**: We found that `html_compiler.ex` doesn't actually compile to static HTML as its name suggests, but transforms AST to Phoenix component calls. For better clarity, we identified `ComponentBuilder.ex` as a more accurate name for this module in future refactoring.
  - If not used, remove the dead code or files. If still used, determine if it will eventaully be migrated by a refactor.
  - Run `./run elixir:test` again.
  
  **Definition of Done:**
  - Database migration script for AST field
  - Schema update with validation
  - Tests pass
  - Migration test with sample production data
    - RUn `./run elixir:lint` then `./run elixir:format` to check for linting and formatting errors
  - Run `./run elixir:test` to make sure all tests pass.

- [ ] **Story 5.2**: Update EntryManager for AST handling
  - Modify content creation/update to generate and store AST
  - Update content retrieval to include AST
  - Implement functions for AST-only operations
  - Maintain compatibility with existing functions
    - RUn `./run elixir:lint` then `./run elixir:format` to check for linting and formatting errors
  - Run `./run elixir:test` to make sure all tests pass.
  - Run `./run elixir:static-analysis`, and triage the errors. Solve the easiest, least impact errors first. Report back the big errors and their causes.
  
  **Definition of Done:**
  - Updated EntryManager with AST handling
  - Unit tests for all new and modified functions
  - API compatibility tests with existing code
  - Performance benchmarks for AST operations

- [ ] **Story 5.3**: Refactor EntryManager into modular components
  - **NOTE**: This task should only begin after fixing AST rendering/serialization issues
  - Address high complexity in EntryManager by splitting into focused modules:
    - `records.ex`: Core database operations for content entries
    - `ast_serialization.ex`: Handle conversion between tuple AST and serializable format
    - `compiler.ex`: Content compilation and transformation
    - `translations.ex`: Translation-specific functionality
    - `source.ex`: File-based content operations
  - Reorganize into `managers/entry/` folder structure
  - Fix existing tests to work with refactored structure
  - Ensure compatibility with all Content context functions
  
  **Definition of Done:**
  - EntryManager functionality split into focused modules
  - Organized folder structure for better maintainability
  - All existing tests passing with refactored structure
  - No regression in functionality or performance
  - Cyclomatic complexity metrics improved
  - All verification steps pass:
    - Format: `./run elixir:format` exits with code 0
    - Lint: `./run elixir:lint` shows improved metrics
    - Tests: `./run elixir:test` passes
    - Static Analysis: `./run elixir:static-analysis` shows reduced warnings

- [ ] **Story 5.4**: Update translation system for component AST compatibility
  - Modify `compile_translations` in EntryManager to handle component AST nodes
  - Update `compile_content` to ensure consistent handling of content and translations
  - Create helper functions for rendering either HTML strings or component AST
  - Maintain backward compatibility with existing translated content
  
  **Definition of Done:**
  - Modified EntryManager translation functions with AST handling
  - Helper functions for template rendering with both HTML and AST
  - LiveView templates updated to use new rendering helpers
  - All translation tests passing with both legacy HTML and new AST content
  - Verify with `./run elixir:test test/portfolio_web/live/case_study_live_show_test.exs`
  - End-to-end tests showing translations work with component AST
  - Performance comparison between HTML string and AST rendering approaches

## Phase 6: LiveView Integration

- [ ] **Story 6.1**: Update LiveView modules for AST rendering
  - Modify mount and handle_params to work with AST
  - Integrate AST rendering helpers
  - Preserve fallback to compiled HTML for compatibility
  - Add error handling for AST rendering failures
  
  **Definition of Done:**
  - Updated LiveView modules with AST rendering
  - Integration tests for the LiveView pipeline
  - Error handling tests for various failure scenarios
  - Performance comparison with previous implementation

- [ ] **Story 6.2**: Create component rendering context
  - Implement function to prepare assigns for component rendering
  - Create mechanism for passing LiveView context to components
  - Add helper for handling component slots
  - Test with various LiveView scenarios
  
  **Definition of Done:**
  - Context preparation module with public API
  - Tests for assigns preparation and propagation
  - Slot handling tests with nested content
  - Component rendering tests in various LiveView states

- [ ] **Story 6.3**: Update templates for AST rendering
  - Update show templates to render content AST
  - Add fallback rendering for legacy content
  - Implement error handling and logging
  - Optimize template rendering
  
  **Definition of Done:**
  - Templates updated with AST rendering code
  - End-to-end tests pass for both AST and legacy content
  - Exception handling tests verify proper error responses
  - Performance tests show rendering meets time thresholds

## Phase 7: Component Development

- [ ] **Story 7.1**: Enhance component documentation
  - Expand component registry with documentation features
  - Create documentation generation tools
  - Add usage examples for registered components
  - Implement versioning for component compatibility
  
  **Definition of Done:**
  - Component documentation system implemented
  - Documentation can be generated for all components
  - Usage examples validated through tests
  - Version compatibility system in place

- [ ] **Story 7.2**: Create example components
  - Implement example components for common use cases
  - Create code example component with syntax highlighting
  - Document component usage in markdown
  
  **Definition of Done:**
  - Example components implemented with tests
  - Documentation with markdown usage examples
  - Visual verification of component rendering
  - All verification steps pass for new components

- [ ] **Story 7.3**: Implement validation integration
  - Create bridge to leverage Phoenix component validation
  - Add custom error messages for component validation failures
  - Implement attribute type conversion and coercion
  - Test with various input scenarios
  
  **Definition of Done:**
  - Validation bridge module implemented
  - Tests for each attribute type validation
  - Error message tests for various validation failures
  - Type coercion tests for all supported types

## Refactoring Verification Process

For each phase of refactoring, we will run the following verification steps:

```bash
# 1. Format the code
./run elixir:format

# 2. Run linting 
./run elixir:lint

# 3. Run tests
./run elixir:test

# 4. Run security checks 
./run elixir:security

# 5. Run static analysis
./run elixir:dialyzer
```

Each phase will only be considered complete when all verification steps pass with no errors or warnings.

## Technical Approach Summary

The implementation will:

1. Adopt a Pipeline-Oriented Architecture:
   - Clear data flow: Markdown → AST → Component Calls
   - Modular transformation stages
   - Explicit component handling

2. Enhance the existing modules with better structure:
   - Improve AST representation
   - Add pipeline orchestration
   - Enhance component definition and registry
   - Better separation of concerns

3. Maintain backward compatibility:
   - Keep existing entry points working
   - Support gradual migration
   - Add new capabilities alongside existing ones
