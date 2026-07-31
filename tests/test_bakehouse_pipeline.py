"""Offline contract tests for the Bakehouse medallion bundle (no Databricks connection)."""

from pathlib import Path

import pytest

ROOT = Path(__file__).resolve().parent.parent
TRANSFORMATIONS = ROOT / "src" / "pipelines" / "bakehouse" / "transformations"
RESOURCES = ROOT / "resources"

EXPECTED_SQL = {
    "bronze": ["transactions", "franchises", "customers", "suppliers", "reviews"],
    "silver": ["franchises", "customers", "transactions", "reviews_sentiment"],
    "gold": [
        "daily_sales_by_franchise",
        "sales_by_product",
        "franchise_performance",
        "sales_by_country",
        "top_customers",
        "sentiment_by_franchise",
        "sales_by_payment_method",
    ],
}

PIPELINE_CONFIG_KEYS = (
    "medallion_catalog",
    "bronze_schema",
    "silver_schema",
    "gold_schema",
)

# Catalog names belong only in databricks.yml targets — never in SQL or resource YAMLs.
FORBIDDEN_CATALOG_LITERALS = ("bakehouse_dev", "bakehouse_prd")


def _sql_files(layer: str) -> list[Path]:
    return sorted((TRANSFORMATIONS / layer).glob("*.sql"))


def _read(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def _code_lines(content: str) -> str:
    """Ignore comment lines when scanning YAML for forbidden literals."""
    return "\n".join(line for line in content.splitlines() if not line.lstrip().startswith("#"))


@pytest.fixture(params=list(EXPECTED_SQL.keys()))
def layer(request: pytest.FixtureRequest) -> str:
    return request.param


class TestProjectLayout:
    def test_bundle_entrypoints_exist(self):
        required = [
            ROOT / "databricks.yml",
            RESOURCES / "schemas.yml",
            RESOURCES / "bakehouse_pipeline.pipeline.yml",
            RESOURCES / "bakehouse_job.job.yml",
            RESOURCES / "bakehouse_dashboard.dashboard.yml",
            ROOT / "src" / "dashboards" / "bakehouse_overview.lvdash.json",
        ]
        missing = [str(p.relative_to(ROOT)) for p in required if not p.is_file()]
        assert not missing, f"Missing files: {missing}"

    @pytest.mark.parametrize("layer,tables", EXPECTED_SQL.items())
    def test_all_sql_files_exist(self, layer: str, tables: list[str]):
        existing = {p.stem for p in _sql_files(layer)}
        assert existing == set(tables), f"{layer}: expected {set(tables)}, got {existing}"


class TestSqlConventions:
    @pytest.mark.parametrize("layer,tables", EXPECTED_SQL.items())
    def test_create_materialized_view_statement(self, layer: str, tables: list[str]):
        for table in tables:
            sql = _read(TRANSFORMATIONS / layer / f"{table}.sql")
            assert "CREATE OR REFRESH MATERIALIZED VIEW" in sql, f"{layer}.{table}: missing CREATE OR REFRESH"
            assert "${medallion_catalog}" in sql, f"{layer}.{table}: must use ${{medallion_catalog}}"
            assert "USE CATALOG" not in sql.upper(), f"{layer}.{table}: must not USE CATALOG"

    @pytest.mark.parametrize("layer,schema_var", [
        ("bronze", "${bronze_schema}"),
        ("silver", "${silver_schema}"),
        ("gold", "${gold_schema}"),
    ])
    def test_layer_uses_correct_schema_variable(self, layer: str, schema_var: str):
        for path in _sql_files(layer):
            assert schema_var in _read(path), f"{path.name}: must reference {schema_var}"

    def test_bronze_ingests_from_samples_bakehouse_with_metadata(self):
        for path in _sql_files("bronze"):
            sql = _read(path)
            assert "samples.bakehouse." in sql, f"{path.name}: must read from samples.bakehouse"
            assert "_ingested_at" in sql, f"{path.name}: missing _ingested_at"
            assert "_source_table" in sql, f"{path.name}: missing _source_table"

    def test_silver_has_expectations(self):
        for path in _sql_files("silver"):
            assert "EXPECT (" in _read(path), f"{path.name}: silver tables should declare expectations"

    def test_silver_reviews_sentiment_uses_ai_function(self):
        sql = _read(TRANSFORMATIONS / "silver" / "reviews_sentiment.sql")
        assert "ai_analyze_sentiment" in sql

    def test_silver_transactions_enriched_from_silver_dimensions(self):
        sql = _read(TRANSFORMATIONS / "silver" / "transactions.sql")
        assert "${medallion_catalog}.${silver_schema}.franchises" in sql
        assert "${medallion_catalog}.${silver_schema}.customers" in sql

    def test_gold_reads_from_silver_only(self):
        for path in _sql_files("gold"):
            sql = _read(path)
            assert "${medallion_catalog}.${silver_schema}." in sql, f"{path.name}: gold must read silver"
            assert "samples.bakehouse." not in sql, f"{path.name}: gold must not read samples directly"

    def test_franchise_performance_includes_geo_columns(self):
        sql = _read(TRANSFORMATIONS / "gold" / "franchise_performance.sql")
        for col in ("latitude", "longitude", "city", "country"):
            assert col in sql, f"franchise_performance missing {col}"


class TestNoHardcodedCatalog:
    def test_sql_files_never_hardcode_catalog_names(self):
        offenders = []
        for path in TRANSFORMATIONS.rglob("*.sql"):
            content = _read(path)
            for literal in FORBIDDEN_CATALOG_LITERALS:
                if literal in content:
                    offenders.append(f"{path.relative_to(ROOT)} contains {literal}")
        assert not offenders, "\n".join(offenders)

    def test_resource_ymls_use_var_catalog(self):
        ymls = list(RESOURCES.glob("*.yml"))
        assert ymls, "no resource yaml files"
        for path in ymls:
            content = _code_lines(_read(path))
            for literal in FORBIDDEN_CATALOG_LITERALS:
                assert literal not in content, f"{path.name} must not hardcode {literal}"
            if path.name in {"schemas.yml", "bakehouse_pipeline.pipeline.yml", "bakehouse_dashboard.dashboard.yml"}:
                assert "${var.catalog}" in content, f"{path.name} must use ${{var.catalog}}"


class TestBundleWiring:
    def test_pipeline_configuration_keys(self):
        content = _read(RESOURCES / "bakehouse_pipeline.pipeline.yml")
        for key in PIPELINE_CONFIG_KEYS:
            assert f"{key}:" in content, f"pipeline missing configuration.{key}"
        assert "serverless: true" in content

    def test_schemas_are_bronze_silver_gold(self):
        content = _read(RESOURCES / "schemas.yml")
        for name in ("bronze", "silver", "gold"):
            assert f"name: {name}" in content

    def test_job_references_pipeline_resource(self):
        content = _read(RESOURCES / "bakehouse_job.job.yml")
        assert "${resources.pipelines.bakehouse_medallion.id}" in content

    def test_dashboard_points_at_gold_schema(self):
        content = _read(RESOURCES / "bakehouse_dashboard.dashboard.yml")
        assert "dataset_catalog: ${var.catalog}" in content
        assert "dataset_schema: ${resources.schemas.gold.name}" in content

    def test_databricks_yml_declares_catalog_per_target(self):
        content = _read(ROOT / "databricks.yml")
        assert "variables:" in content and "catalog:" in content
        assert "catalog: bakehouse_dev" in content
        assert "catalog: bakehouse_prd" in content
