# Test Failure Analysis for Task 3 Cleanup

## Overview

During the refactoring for Task 3 (cleanup of compilation-related functions from EntryManager), we encountered several test failures. This document analyzes these failures in detail to understand what needs to be fixed.

## Test Failures

1. **AST vs HTML Format Issues** (Tests 1, 3, 4, 5):
   ```
   Expected truthy, got false
   code: assert is_list(compiled_content)
   arguments: "<p>English Content</p>"
   ```
   These tests expect `compiled_content` to be an AST (a list structure), but our refactored code is returning HTML strings instead. The Compiler module's functions now consistently return compiled HTML content in these cases where the tests expected the raw AST structure.

2. **HTML Wrapping Issue** (Test 2):
   ```
   Assertion with == failed
   code: assert text_content == "Contenu Français"
   left: "<p>Contenu Français</p>"
   right: "Contenu Français"
   ```
   This test expects raw text content, but our implementation is correctly wrapping it in HTML paragraph tags. The test expects the raw string, not the properly formatted HTML.

3. **LiveView Pattern Matching Failures** (Tests 6, 7):
   ```
   ** (CaseClauseError) no case clause matching: {:ok, %Portfolio.Content.Schemas.CaseStudy{...
   ```
   These failures occur in the LiveView tests where the code is pattern-matching on the return value from `get_content_with_translations`. Our refactoring changed the structure of the returned data, breaking the pattern matching in the tests or in the LiveView code.

## Root Cause

The core issue is that our refactoring changed the behavior of compilation functions:
- **Before**: Some functions returned AST structures (as lists) and others returned HTML strings
- **After**: All functions now consistently return compiled HTML strings

While this makes the code more consistent, it breaks tests that were expecting the mixed behavior. Our `compile_translations_with_compiler` function is returning HTML content for translated fields where the tests expect AST structures.

The refactoring also affects how the LiveView code is receiving and displaying content, as it was probably designed to handle the previous mixed format structure.

## Recommendation

To fix these issues, we need to:

1. Update the `compile_translations_with_compiler` function to return AST structures for fields where the tests expect them
2. Fix the LiveView code to handle the new return structure from `get_content_with_translations`
3. Consider adding more explicit documentation about the return types of these functions to prevent future confusion

## TranslationsTest Module Failures

After creating the new Translations module and its tests, we encountered two specific failures:

1. **Sorting Test Assertion Failure**:
   ```elixir
   # Line 91-101 in translations_test.exs
   test "handles sorting options" do
     result_asc = Translations.list_with_translations("note", [sort_order: :asc], "en")
     result_desc = Translations.list_with_translations("note", [sort_order: :desc], "en")
     
     # ...
     
     # This assertion fails - both lists have identical ordering
     if length(result_asc) > 1 and length(result_desc) > 1 do
       assert Enum.map(result_asc, & &1.id) != Enum.map(result_desc, & &1.id)
     end
   end
   ```
   **Root Cause**: The test fixtures likely have identical values for the default sort field (probably `inserted_at`), causing both ascending and descending sorts to produce the same order. This is a brittle test that depends on specific data characteristics.

2. **Invalid Sort Parameter Causing Exception**:
   ```elixir
   # Line 84-87 in translations_test.exs
   test "handles empty results" do
     # Using a content type with no entries
     result = Translations.list_with_translations("case_study", [sort_by: :invalid_sort], "en")
     assert is_list(result)
     assert result == []
   end
   ```
   **Error**: 
   ```
   ** (ArgumentError) expected one of :asc, :asc_nulls_last, :asc_nulls_first, :desc, :desc_nulls_last, :desc_nulls_first in `order_by`, got: `nil`
   ```
   **Root Cause**: The Records module isn't validating the `sort_by` parameter properly before passing it to Ecto's `order_by` clause. The invalid `:invalid_sort` value causes the database query to fail.

## Recommendation for TranslationsTest Fixes

1. **For the sorting test**:
   - Avoid testing implementation details like exact sort order
   - Test only that the function returns a valid list structure
   - Alternatively, create test data with guaranteed different sort values

2. **For the invalid parameter test**:
   - Modify the Records module to validate sort parameters before using them
   - Or update the test to use a valid but unused sort field
   - Consider testing error handling rather than assuming the function should succeed with invalid input
