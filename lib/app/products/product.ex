defmodule App.Products.Product do
  use Ecto.Schema
  use Waffle.Ecto.Schema

  import Ecto.Changeset
  alias App.Utils.ReservedWords

  @derive {
    Flop.Schema,
    filterable: [:is_live, :is_public], sortable: [:inserted_at]
  }

  @types ~w(downloadable)a

  @price_type_options [
    {"Harga tetap", :fixed},
    {"Harga ditentukan pembeli", :flexible},
    {"Gratis", :free}
  ]
  @price_types @price_type_options |> Enum.map(&elem(&1, 1))

  @required_fields ~w(name slug price price_type cta)a
  @optional_fields ~w(is_live is_public description)a

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "products" do
    field :name, :string
    field :slug, :string
    field :type, Ecto.Enum, values: @types, default: :downloadable
    field :price, :integer
    field :price_type, Ecto.Enum, values: @price_types
    field :description, :string
    field :is_live, :boolean, default: false
    field :is_public, :boolean, default: false
    field :cta, :string, default: "Beli"

    belongs_to :user, App.Users.User
    has_many :images, App.Products.Image
    has_many :variants, App.Products.Variant
    has_many :orders, App.Orders.Order
    has_many :contents, App.Contents.Content

    embeds_many :attributes, App.Products.Attribute, on_replace: :delete
    embeds_one :thanks_page_config, App.Products.ThanksPageConfig, on_replace: :delete

    timestamps(type: :utc_datetime)
  end

  def price_type_options(), do: @price_type_options

  @doc false
  def changeset(product, attrs) do
    product
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> cast_embed(:thanks_page_config, with: &App.Products.ThanksPageConfig.changeset/2)
    |> cast_embed(:attributes, with: &App.Products.Attribute.changeset/2)
    |> validate_length(:name, max: 50, message: "maksimum %{count} karakter")
    |> validate_required(@required_fields)
    |> validate_price()
    |> validate_slug()
  end

  def create_changeset(product, attrs) do
    product
    |> changeset(attrs)
    |> validate_user(attrs)
  end

  defp validate_price(changeset) do
    min_price = Application.get_env(:app, :min_price, 10_000)
    price = get_field(changeset, :price)
    price_type = get_field(changeset, :price_type)

    cond do
      price_type == :free ->
        changeset

      price < min_price ->
        add_error(changeset, :price, "Minimum Rp. #{min_price}")

      true ->
        changeset
    end
  end

  defp validate_slug(changeset) do
    changeset
    |> validate_length(:slug, min: 3, max: 150)
    |> validate_format(:slug, ~r/^[a-zA-Z0-9_\-]+$/)
    |> validate_reserved_words(:slug)
    |> unsafe_validate_unique([:user_id, :slug], App.Repo, error_key: :slug)
    |> unique_constraint([:user_id, :slug], error_key: :slug)
  end

  defp validate_user(changeset, attrs) do
    case Map.get(attrs, "user") do
      nil -> add_error(changeset, :user, "can't be blank")
      user -> put_assoc(changeset, :user, user)
    end
  end

  defp validate_reserved_words(changeset, field) do
    validate_change(changeset, field, fn _, value ->
      if ReservedWords.is_reserved?(value) do
        [{field, "is reserved"}]
      else
        []
      end
    end)
  end
end
