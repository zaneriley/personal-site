# Critical Infrastructure Protection Rules

## Protected Files - DO NOT MODIFY Without Team Approval

0. **NEVER modify these critical files without explicit team discussion and approval**:
   - `config/test.exs` - Contains SQL Sandbox configuration critical for test isolation
   - `config/runtime.exs` - Can override environment-specific configurations
   - `test/test_helper.exs` - Sets up test environment and initializes SQL Sandbox
   - `test/support/data_case.ex` - Controls transaction isolation for tests
   - `lib/portfolio/application.ex` - Controls application startup sequence

## Configuration Management Requirements

1. **ALWAYS use merging for configuration changes**:
   - When modifying configuration in `runtime.exs`, use `Keyword.merge/2` to preserve existing settings
   - Example: `config :portfolio, Portfolio.Repo, Keyword.merge(existing_config, [hostname: db_host])`
   - NEVER replace entire configuration blocks with new values

2. **NEVER change environment detection mechanisms**:
   - Maintain consistent environment detection throughout the application
   - Use `config_env()` at compile time and `Application.get_env(:portfolio, :environment)` at runtime
   - Document ALL environment-dependent code with clear comments

3. **DATABASE configuration modifications require special care**:
   - SQL Sandbox settings MUST be preserved in test environment
   - Pool settings are critical and environment-specific
   - Test database configuration requires `pool: Ecto.Adapters.SQL.Sandbox` setting

## Process for Critical Infrastructure Changes

1. **Mandatory review process**:
   - Explicitly document WHY a change to critical files is necessary
   - Explain HOW the change preserves existing functionality
   - Run the FULL test suite before and after changes
   - Get written approval from at least one senior developer

2. **Testing verification required**:
   - Changes to configuration MUST include verification of all environments
   - Test environment changes require special scrutiny
   - Document test results before submitting changes

3. **Infrastructure changes documentation**:
   - Add detailed inline comments explaining rationale for any critical file changes
   - Update team documentation with details of configuration changes
   - Explain potential side effects and considerations

## Ecto and Database Testing Best Practices

1. **Understand SQL Sandbox requirements**:
   - Test isolation requires `pool: Ecto.Adapters.SQL.Sandbox`
   - Each test must run in a transaction that is rolled back
   - Configuration must support ownership tracking

2. **Configuration precedence awareness**:
   - Environment-specific configs (`test.exs`) are loaded before runtime configs
   - Runtime configs can override environment configs
   - Maintain awareness of the complete config loading sequence

3. **NEVER disable transaction isolation in tests**:
   - All tests must run inside transactions that are rolled back
   - Changes to `DataCase` or test setup must preserve isolation
   - Test side effects must be contained within transactions
