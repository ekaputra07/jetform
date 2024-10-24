defmodule AppWeb.AdminLive.Product.Components.Settings do
  use AppWeb, :live_component
  alias App.Products

  @impl true
  def render(assigns) do
    ~H"""
    <div id={"settings-for-product-" <> @id} class="p-4 md:p-8 dark:bg-gray-800 space-y-4">
      <div class="border-b pb-2  items-center justify-between">
        <h2 class="text-lg font-semibold">Setelah Pembayaran</h2>
        <p class="text-xs text-gray-500">
          Tampilkan halaman terima kasih atau redirect ke halaman lain.
        </p>
      </div>
      <.simple_form
        for={@form}
        phx-update="replace"
        phx-change="validate"
        phx-submit="save"
        phx-target={@myself}
      >
        <div class="space-y-6">
          <.input
            field={@form[:type]}
            type="select"
            label="Tipe"
            options={App.Products.thanks_page_type_options()}
            required
          />
          <.input
            :if={@form[:type].value == "redirect"}
            field={@form[:redirect_url]}
            label="URL"
            type="text"
            required
            placeholder="https://..."
          />
          <.input
            :if={@form[:type].value == "message"}
            field={@form[:title]}
            label="Judul"
            type="text"
            placeholder="Terima kasih!"
          />
          <div
            :if={@form[:type].value == "message"}
            id="trix-editor-thanks-message"
            phx-update="ignore"
          >
            <label class="text-sm font-medium mb-2 block">Pesan</label>
            <.input field={@form[:message]} type="hidden" phx-hook="InitTrix" />
            <trix-editor input="thanks_page_config_message" class="trix-content"></trix-editor>
          </div>

          <div :if={@form[:type].value == "message"} class="flex">
            <div class="flex items-center h-5">
              <.input field={@form[:show_brand_logo]} type="checkbox" />
            </div>
            <div class="ms-2 text-sm">
              <label for="helper-checkbox" class="font-medium text-gray-900 dark:text-gray-300">
                Tampilkan logo
              </label>
              <p
                id="helper-checkbox-text"
                class="text-xs font-normal text-gray-500 dark:text-gray-300"
              >
                Silahkan upload logo Anda di pengaturan akun sebelum bisa menggunakan opsi ini.
              </p>
            </div>
          </div>

          <div :if={@form[:type].value == "message"} class="flex">
            <div class="flex items-center h-5">
              <.input field={@form[:message_left_aligned]} type="checkbox" />
            </div>
            <div class="ms-2 text-sm">
              <label for="helper-checkbox" class="font-medium text-gray-900 dark:text-gray-300">
                Format pesan rata kiri
              </label>
              <p
                id="helper-checkbox-text"
                class="text-xs font-normal text-gray-500 dark:text-gray-300"
              >
                Disarankan apabila pesan Anda lumayan panjang dan terdiri dari beberapa paragraf (agar mudah dibaca).
              </p>
            </div>
          </div>

          <div class="p-2 text-xs text-slate-600 bg-slate-200 rounded-md">
            <div class="font-medium mb-2">
              Gunakan kode di bawah ini untuk menampilkan data terkait order pada Judul, Pesan, atau URL Redirect:
            </div>
            <div class="font-mono">{{NAMA}} = Nama pembeli</div>
            <div class="font-mono">{{EMAIL}} = Nama pembeli</div>
            <div class="font-mono">{{PHONE}} = Nomor HP/WA pembeli</div>
          </div>
        </div>

        <:actions>
          <div class="mt-8 text-right">
            <.button
              phx-disable-with="Menyimpan..."
              class="w-full px-5 py-2 text-base font-medium text-center text-white bg-primary-600 rounded-md hover:bg-primary-700 focus:ring-4 focus:ring-primary-300 sm:w-auto"
            >
              Simpan
            </.button>
          </div>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{id: id} = assigns, socket) do
    product = Products.get_product!(id)
    changeset = changeset(product, %{})

    socket =
      socket
      |> assign(assigns)
      |> assign(:product, product)
      |> assign(:form, to_form(changeset))

    {:ok, assign(socket, assigns)}
  end

  @impl true
  def handle_event("validate", %{"thanks_page_config" => config_params}, socket) do
    cs = changeset(socket.assigns.product, config_params) |> Map.put(:action, :validate)
    send(self(), {:thanks_config_updated, Ecto.Changeset.apply_changes(cs)})
    {:noreply, assign(socket, :form, to_form(cs))}
  end

  @impl true
  def handle_event("save", params, socket) do
    form =
      case Products.update_product(socket.assigns.product, params) do
        {:ok, product} ->
          send(self(), {:thanks_config_updated, product.thanks_page_config})
          send(self(), {:flash, :info, "Pengaturan 'Setelah Pembayaran' berhasil disimpan."})
          changeset(product, %{}) |> to_form()

        {:error, changeset} ->
          to_form(changeset)
      end

    {:noreply, assign(socket, :form, form)}
  end

  defp changeset(product, attrs) do
    case product.thanks_page_config do
      nil -> Products.change_thanks_page_config(%Products.ThanksPageConfig{}, attrs)
      config -> Products.change_thanks_page_config(config, attrs)
    end
  end
end
