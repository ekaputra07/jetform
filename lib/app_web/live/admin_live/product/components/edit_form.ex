defmodule AppWeb.AdminLive.Product.Components.EditForm do
  use AppWeb, :html
  alias App.Products

  @doc """
  Renders basic product editor form
  """
  attr :on_change, :string, default: "validate"
  attr :on_submit, :string, default: "save"
  attr :current_user, :map, required: true
  attr :product, :map, required: true
  attr :changeset, :map, required: true

  def render(assigns) do
    assigns = assigns |> assign(:has_variants, Products.has_variants?(assigns.product, true))

    ~H"""
    <.simple_form
      :let={f}
      for={@changeset}
      phx-change={@on_change}
      phx-submit={@on_submit}
      phx-update="replace"
    >
      <div>
        <div class="p-4 md:p-8 bg-white dark:bg-gray-800 space-y-6">
          <.error :if={@changeset.action && not @changeset.valid?}>
            Oops, something went wrong! Please check the errors below.
          </.error>
          <.input field={f[:name]} type="text" label="Nama produk" required />
          <.input field={f[:slug]} type="text" label="URL" required>
            <:help>
              <div class="mt-2 text-xs text-gray-500 dark:text-gray-400">
                <.link
                  href={AppWeb.Utils.product_url(@product, preview: !@product.is_live)}
                  target="_blank"
                >
                  <%= AppWeb.Utils.product_url(@product) %>
                  <.icon
                    name="hero-arrow-top-right-on-square"
                    class="w-4 h-4 inline-block text-primary-500"
                  />
                </.link>
              </div>
            </:help>
          </.input>

          <.input
            :if={!@has_variants}
            field={f[:price_type]}
            options={App.Products.price_type_options()}
            type="select"
            label="Tipe harga"
            required
          />
          <.input
            :if={!@has_variants and show_price_input?(@changeset)}
            field={f[:price]}
            type="number"
            label={
              if Ecto.Changeset.get_field(@changeset, :price_type) == :flexible,
                do: "Harga minimum",
                else: "Harga"
            }
            required
          >
            <:help>
              <div class="pt-3 text-xs text-yellow-500 leading-tight">
                <.icon name="hero-exclamation-circle w-4 h-4" />
                Beberapa bank menetapkan nilai minimal transaksi sebesar
                <.price value={Application.get_env(:app, :minimum_price)} />.
              </div>
            </:help>
          </.input>
          <.input field={f[:cta]} type="text" label="Call To Action (CTA)" required />
        </div>

        <hr />
        <div class="p-4 md:p-8 bg-gray-50 dark:bg-gray-800 space-y-6">
          <div>
            <p class="font-normal flex items-center">
              <.icon name="hero-newspaper me-1" />Deskripsi produk
            </p>
          </div>

          <div id="trix-editor-product-description" phx-update="ignore">
            <.input field={f[:description]} type="hidden" phx-hook="InitTrix" />
            <trix-editor input="product_description" class="trix-content"></trix-editor>
          </div>
        </div>

        <hr />
        <div class="p-4 md:p-8 bg-white dark:bg-gray-800 space-y-6">
          <.attributes_input field={f[:attributes]} />
        </div>

        <hr />
        <%!-- <div class="p-4 md:p-8 bg-gray-50 dark:bg-gray-800 space-y-6">
          <div>
            <p class="font-normal flex items-center">
              <.icon name="hero-cog-6-tooth me-1" />Pengaturan tambahan
            </p>
            <p class="pl-6 mt-1 text-xs text-gray-500">
              Membatasi jumlah pembelian atau batas waktu pembelian bisa membuat produk anda lebih eksklusif.
            </p>
          </div>

          <div
            :if={@has_variants}
            class="p-4 mb-4 text-sm text-yellow-800 rounded-md bg-yellow-50 dark:bg-gray-800 dark:text-yellow-400 border border-yellow-600"
            role="alert"
          >
            <span class="font-medium"><.icon name="hero-hand-raised" />Perhatian!</span>
            Pengaturan ini tidak berlaku karena anda memiliki varian produk. Pengaturan serupa harus diterapkan pada masing-masing varian produk.
          </div>


          <div class="flex">
            <div class="flex items-center h-5">
              <input
                id="helper-checkbox1"
                aria-describedby="helper-checkbox-text"
                type="checkbox"
                value=""
                class="w-4 h-4 text-blue-600 bg-gray-100 border-gray-300 rounded focus:ring-blue-500 dark:focus:ring-blue-600 dark:ring-offset-gray-800 focus:ring-2 dark:bg-gray-700 dark:border-gray-600"
              />
            </div>
            <div class="ms-2 text-sm">
              <label for="helper-checkbox" class="font-medium text-gray-900 dark:text-gray-300">
                Batasi jumlah pembelian
              </label>
              <p
                id="helper-checkbox-text1"
                class="text-xs font-normal text-gray-500 dark:text-gray-300"
              >
                Produk hanya bisa dibeli ketika jumlah pembelian belum mencapai batas tertentu.
              </p>
            </div>
          </div>

          <div class="flex">
            <div class="flex items-center h-5">
              <input
                id="helper-checkbox2"
                aria-describedby="helper-checkbox-text"
                type="checkbox"
                value=""
                class="w-4 h-4 text-blue-600 bg-gray-100 border-gray-300 rounded focus:ring-blue-500 dark:focus:ring-blue-600 dark:ring-offset-gray-800 focus:ring-2 dark:bg-gray-700 dark:border-gray-600"
              />
            </div>
            <div class="ms-2 text-sm">
              <label for="helper-checkbox" class="font-medium text-gray-900 dark:text-gray-300">
                Batasi waktu pembelian
              </label>
              <p
                id="helper-checkbox-text2"
                class="text-xs font-normal text-gray-500 dark:text-gray-300"
              >
                Produk hanya bisa dibeli sampai tanggal tertentu.
              </p>
            </div>
          </div>
        </div> --%>
      </div>
      <:actions :let={f}>
        <div class="flex items-center justify-between p-4 dark:bg-gray-800">
          <div class="flex gap-2 text-gray-800 text-sm mt-4">
            Produk Aktif <.input field={f[:is_live]} type="tw-toggle" />
          </div>

          <.button
            phx-disable-with="Menyimpan..."
            class="px-8 py-3 text-base font-medium text-white bg-primary-600 rounded-md hover:bg-primary-700 focus:ring-4 focus:ring-primary-300 sm:w-auto dark:bg-primary-600 dark:hover:bg-primary-600 dark:focus:ring-primary-800"
          >
            Simpan
          </.button>
        </div>
      </:actions>
    </.simple_form>
    """
  end

  attr :field, :map, required: true
  attr :on_add, :string, default: "add_attribute"
  attr :on_delete, :string, default: "delete_attribute"

  def attributes_input(assigns) do
    ~H"""
    <div phx-feedback-for="attributes">
      <.label>Atribut Tambahan</.label>
      <p class="mt-1 mb-2 text-xs text-gray-500">
        Bisa digunakan untuk menampilkan spesifikasi produk dalam format tabel.
      </p>
      <.inputs_for :let={attr} field={@field}>
        <div class="flex gap-2 items-center">
          <.input field={attr[:key]} type="text" placeholder="Nama atribut" wrapper_class="flex-1" />
          <span class="flex-none inline-flex">=</span>
          <.input field={attr[:value]} type="text" placeholder="Nilai atribut" wrapper_class="flex-1" />
          <.button
            phx-click={@on_delete}
            phx-value-index={attr.index}
            type="button"
            class="self-center flex-none text-red-600 hover:text-white border border-red-600 hover:bg-red-600 focus:ring-4 focus:outline-none focus:ring-red-300 font-medium rounded-md text-sm px-3 py-2 mt-2 text-center dark:border-red-600 dark:text-red-500 dark:hover:text-white dark:hover:bg-red-500 dark:focus:ring-red-600"
          >
            <.icon name="hero-trash w-4 h-4" />
          </.button>
        </div>
      </.inputs_for>

      <.button
        phx-click={@on_add}
        type="button"
        class="mt-2 w-full bg-primary-600 hover:bg-primary-700 text-white border focus:ring-4 focus:outline-none focus:ring-primary-300 font-medium rounded-md text-sm px-5 py-3 text-center me-2 mb-2"
      >
        <.icon name="hero-plus-small w-4 h-4" />Tambah Atribut
      </.button>
    </div>
    """
  end

  defp show_price_input?(changeset) do
    Map.get(changeset.changes, :price_type, changeset.data.price_type) != :free
  end
end
