import { useState, useEffect } from 'react';
import styles from './App.module.css';
import ImageClient from './lib/ImageClient';

type Image = {
  prompt: string;
  keywords: string[];
  image_name: string;
  image_url: string;
  created_at: string;
};

const client = new ImageClient({ baseUrl: 'http://139.162.161.16:80/api' });

const App = () => {
  const [images, setImages] = useState<Image[]>([]);
  const [isLoading, setIsLoading] = useState(true);

  // Fetch images from the API on component mount.
  useEffect(() => {
    const fetchImageData = async () => {
      try {
        const data = await client.getImages();
        setImages(data);
        setIsLoading(false);
      } catch (error) {
        console.error(error);
        setIsLoading(false);
      }
    };
    fetchImageData();
  }, []);

  const handlePostImage = async () => {
    try {
      const data = await client.createImage();
      console.log({data})
    } catch (error) {
      console.error('Error posting image:', error);
    }
  };

  if (isLoading) {
    return <p>Loading...</p>;
  }

  const rows = images.map((image, index) => (
    <div key={index} className={styles.imageCard}>
      <img
        src={image.image_url}
        alt={`Image ${index}`}
        className={styles.responsiveImage}
      />
      <div className={styles.textBlock}>
        {/* Display prompt as a quote */}
        <blockquote className={styles.prompt}>{image.prompt}</blockquote>
        {/* Display keywords after the prompt */}
        <div className={styles.keywords}>
          {image.keywords.map((keyword, idx) => (
            <span key={idx} className={styles.keywordPill}>
              {keyword}
            </span>
          ))}
        </div>
      </div>
    </div>
  ));

  return (
    <div className={styles.container}>
      <header className={styles.header}>
        <h1>Supreme AI Image Generator</h1>
        <nav className={styles.menu}>
          <button onClick={handlePostImage} className={styles.actionButton}>
            Add Image
          </button>
        </nav>
      </header>
      <div className={styles.imageGrid}>{rows}</div>
    </div>
  );
};

export default App;
