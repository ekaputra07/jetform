defmodule App.Repo.Migrations.CreateOrders do
  use Ecto.Migration

  def change do
    create table(:orders, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :user_id, references(:users, type: :binary_id, on_delete: :delete_all), null: false
      add :customer_name, :string, null: false
      add :customer_email, :string, null: false
      add :customer_phone, :string
      add :product_id, references(:products, type: :binary_id)
      add :product_name, :string
      add :product_variant_id, references(:product_variants, type: :binary_id)
      add :product_variant_name, :string
      add :discount_name, :string
      add :discount_value, :integer, default: 0
      add :sub_total, :integer, default: 0
      add :total, :integer, default: 0
      add :valid_until, :utc_datetime
      add :status, :string, null: false

      timestamps(type: :utc_datetime)
    end

    create index(:orders, [:customer_email])
    create index(:orders, [:user_id, :product_id, :product_variant_id])
  end
end
