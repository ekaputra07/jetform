defmodule App.Products do
  import Ecto.Query
  alias App.Repo
  alias App.Products.{Product, Variant, Image, ImageUploader, ThanksPageConfig}

  # --------------- PRODUCT ---------------
  defdelegate price_type_options, to: Product

  def has_attributes?(%Product{attributes: nil}), do: false
  def has_attributes?(%Product{attributes: []}), do: false
  def has_attributes?(%Product{}), do: true

  def list_products_by_user!(user, query) do
    from(p in Product,
      join: u in assoc(p, :user),
      left_join: i in assoc(p, :images),
      preload: [user: u, images: i]
    )
    |> list_products_by_user_scope(user)
    |> Flop.validate_and_run!(query)
  end

  defp list_products_by_user_scope(q, %{role: :admin}), do: q

  defp list_products_by_user_scope(q, user) do
    where(q, [p], p.user_id == ^user.id)
  end

  def get_product(id) do
    Product
    |> Repo.get(id)
  end

  def get_product!(id) do
    Product
    |> Repo.get!(id)
  end

  def get_live_product!(id) do
    Repo.get_by!(Product, id: id, is_live: true)
  end

  def get_product_by_slug!(slug) do
    Repo.get_by!(Product, slug: slug)
  end

  def get_product_by_user_and_slug!(user, slug) do
    Repo.get_by!(Product, user_id: user.id, slug: slug)
  end

  def get_live_product_by_user_and_slug!(user, slug) do
    Repo.get_by!(Product, user_id: user.id, slug: slug, is_live: true)
  end

  def change_product(product, attrs) do
    Product.changeset(product, attrs)
  end

  def create_product(attrs) do
    %Product{}
    |> Product.create_changeset(attrs)
    |> Repo.insert()
  end

  def update_product(product, attrs) do
    product
    |> Product.changeset(attrs)
    |> Repo.update()
  end

  def delete_product(product) do
    Repo.delete(product)
  end

  def cover_url(product, version, opts \\ []) do
    product = Repo.preload(product, :images)

    case Enum.fetch(product.images, 0) do
      {:ok, image} -> ImageUploader.url({image.attachment, image}, version, opts)
      _ -> ImageUploader.default_url(version, product)
    end
  end

  def price_display(product) do
    with true <- has_variants?(product, true),
         [_ | _] = prices <- list_variants_price_by_product(product, true) do
      if Enum.count(prices) == 1 do
        App.Utils.Commons.format_price(Enum.at(prices, 0))
      else
        min_price = Enum.min(prices) |> App.Utils.Commons.format_price()
        max_price = Enum.max(prices) |> App.Utils.Commons.delimited_number()
        min_price <> " - " <> max_price
      end
    else
      _ ->
        formatted_price = App.Utils.Commons.format_price(product.price)

        case product.price_type do
          :free -> "Gratis"
          :fixed -> formatted_price
          :flexible -> "Mulai " <> formatted_price
        end
    end
  end

  # --------------- VARIANT ---------------

  def variants_count(product, active_only \\ false) do
    from(
      v in Variant,
      where: v.product_id == ^product.id,
      select: count(v.id)
    )
    |> then(fn q -> if active_only, do: where(q, [v], v.is_active == true), else: q end)
    |> Repo.one()
  end

  def has_variants?(product, active_only \\ false) do
    variants_count(product, active_only) > 0
  end

  def list_variants_by_product(product, active_only \\ false) do
    from(
      v in Variant,
      where: v.product_id == ^product.id,
      order_by: [asc: v.price]
    )
    |> then(fn q -> if active_only, do: where(q, [v], v.is_active == true), else: q end)
    |> Repo.all()
  end

  def list_variants_price_by_product(product, active_only \\ false) do
    from(
      v in Variant,
      where: v.product_id == ^product.id,
      order_by: [asc: v.price],
      select: v.price
    )
    |> then(fn q -> if active_only, do: where(q, [v], v.is_active == true), else: q end)
    |> Repo.all()
  end

  def get_variant!(id) do
    Repo.get!(Variant, id)
  end

  def change_variant(variant, attrs) do
    Variant.changeset(variant, attrs)
  end

  def create_variant(attrs) do
    %Variant{}
    |> Variant.create_changeset(attrs)
    |> Repo.insert()
  end

  def update_variant(variant, attrs) do
    variant
    |> Variant.changeset(attrs)
    |> Repo.update()
  end

  def delete_variant(variant) do
    Repo.delete(variant)
  end

  # --------------- IMAGE ---------------

  def list_images(product) do
    from(i in Image, where: i.product_id == ^product.id)
    |> Repo.all()
  end

  def get_image!(id) do
    Repo.get!(Image, id)
  end

  def change_image(image, attrs \\ %{}) do
    Image.changeset(image, attrs)
  end

  def create_image(attrs) do
    Ecto.Multi.new()
    |> Ecto.Multi.insert(:image, change_image(%Image{}, attrs))
    |> Ecto.Multi.update(:image_with_attachment, fn %{image: image} ->
      Image.attachment_changeset(image, attrs)
    end)
    |> Repo.transaction(timeout: Application.fetch_env!(:app, :db_transaction_timeout))
    |> case do
      {:ok, %{image_with_attachment: image}} ->
        {:ok, image}

      {:error, _op, changeset} ->
        {:error, changeset}
    end
  end

  def update_image(image, attrs) do
    image
    |> change_image(attrs)
    |> Repo.update()
  end

  def delete_image(image) do
    Ecto.Multi.new()
    |> Ecto.Multi.delete(:delete_record, image)
    |> Ecto.Multi.run(:delete_file, fn _repo, _changes ->
      ImageUploader.delete({image.attachment, image})
      {:ok, image}
    end)
    |> Repo.transaction(timeout: Application.fetch_env!(:app, :db_transaction_timeout))
  end

  def image_url(image, version, opts \\ []) do
    ImageUploader.url({image.attachment, image}, version, opts)
  end

  def image_size_kb(image) do
    size = image.attachment_size_byte || 0
    "#{Float.round(size / 1000, 2)} KB"
  end

  # --------------- THANKS PAGE CONFIG ---------------
  defdelegate thanks_page_type_options, to: ThanksPageConfig, as: :type_options

  def change_thanks_page_config(config, attrs) do
    ThanksPageConfig.changeset(config, attrs)
  end
end
