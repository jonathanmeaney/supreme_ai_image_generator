export type Image = {
  id: number;
  prompt: string;
  keywords: string[];
  image_name: string;
  image_url: string;
  created_at: string;
  status: string;
};

export type Pagination = {
  total_count:  number;
  total_pages:  number;
  current_page: number;
  per_page:     number;
};


class ImageClient {
  baseUrl: string;

  constructor({ baseUrl }: { baseUrl: string }) {
    this.baseUrl = baseUrl;
  }

  async getImages(
    page: number = 1,
    perPage: number = 10
  ): Promise<{ images: Image[]; pagination: Pagination }> {
    const res = await fetch(
      `${this.baseUrl}/images?page=${page}&per_page=${perPage}`
    );
    if (!res.ok) {
      throw new Error(`Error fetching data: ${res.statusText}`);
    }
    const json: { images: Image[]; pagination: Pagination } = await res.json();
    return json;
  }

  // Create a new image on the server.
  async createImage(): Promise<Image> {
    const response: Response = await fetch(`${this.baseUrl}/images`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
    });

    if (!response.ok) {
      throw new Error(`Error posting image: ${response.statusText}`);
    }

    const data: Image = await response.json();
    return data;
  }
}

export default ImageClient;
