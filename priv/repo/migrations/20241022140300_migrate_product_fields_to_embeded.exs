defmodule App.Repo.Migrations.AddAttributesToProducts do
  use Ecto.Migration

  def up do
    alter table(:products) do
      remove :details
      remove :cover
      remove :cta_text
      add :attributes, :map
    end
  end

  def down do
    alter table(:products) do
      add :details, :string
      add :cover, :string
      add :cta_text, :string
      remove :attributes
    end
  end
end
