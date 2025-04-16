type Image = {
  prompt: string;
  keywords: string[];
  image_name: string;
  image_url: string;
  created_at: string;
};

class ImageClient {
  baseUrl: string;

  constructor({ baseUrl }: { baseUrl: string }) {
    this.baseUrl = baseUrl;
  }

  async getImages(): Promise<Image[]> {
    const response: Response = await fetch(`${this.baseUrl}/images`);

    if (!response.ok) {
      throw new Error(`Error fetching data: ${response.statusText}`);
    }

    const json: Image[] = await response.json();
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
