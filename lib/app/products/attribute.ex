defmodule App.Products.Attribute do
  use Ecto.Schema
  import Ecto.Changeset

  embedded_schema do
    field :key, :string
    field :value, :string
  end

  def changeset(attributes, attrs) do
    cast(attributes, attrs, [:key, :value])
  end
end
