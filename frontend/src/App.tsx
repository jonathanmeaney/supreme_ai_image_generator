import { ChangeEvent, useState, useEffect } from 'react';
import styles from './App.module.css';
import ImageClient, { Image, Pagination } from './lib/ImageClient';

const client = new ImageClient({ baseUrl: '/api' });

interface NavigationProps {
  pagination: Pagination;
  handlePrev: () => void;
  handleNext: () => void;
  handlePerPageChange: (e: ChangeEvent<HTMLSelectElement>) => void;
  setPage: (page: number) => void;
}

interface ImageProps {
  image: Image;
  onComplete: () => void;
};

const Navigation = ({
  pagination,
  handlePrev,
  handleNext,
  handlePerPageChange,
  setPage
} : NavigationProps) => {
  return (
    <div className={styles.pagination}>
      <div className={styles.prevNext}>
        <button onClick={handlePrev} disabled={pagination.current_page === 1}>
          ← Prev
        </button>
        <span className={styles.currentLabel}>
          Page {pagination.current_page} of {pagination.total_pages}
        </span>
        <button
          onClick={handleNext}
          disabled={pagination.current_page === pagination.total_pages}
        >
          Next →
        </button>
      </div>

      <div className={styles.perPage}>
        <label>
          Per page:
          <select
            value={pagination.per_page}
            onChange={handlePerPageChange}
            className={styles.perPageSelect}
          >
            {[1, 5, 10, 20, 50].map(n => (
              <option key={n} value={n}>{n}</option>
            ))}
          </select>
        </label>
      </div>

      <div className={styles.pageButtons}>
        {Array.from({ length: pagination.total_pages }, (_, i) => i + 1).map(p => (
          <button
            key={p}
            onClick={() => setPage(p)}
            className={
              p === pagination.current_page
                ? `${styles.pageButton} ${styles.pageButtonActive}`
                : styles.pageButton
            }
          >
            {p}
          </button>
        ))}
      </div>
    </div>
  );
};

const ImageContainer = ({ image, onComplete }: ImageProps) => {
  useEffect(() => {
    // if the record is still pending or in_progress, start polling
    if (['pending', 'in_progress'].includes(image.status)) {
      const interval = setInterval(async () => {
        try {
          const res = await fetch(`/api/images/${image.id}`);
          if (!res.ok) throw new Error(res.statusText);
          const updated: Image = await res.json();

         onComplete();

          // stop polling once we're complete (or error, if you like)
          if (updated.status === 'complete') {
            clearInterval(interval);
          }
        } catch (e) {
          console.error('Failed to poll image status:', e);
          // optional: you might choose to clearInterval here on certain errors
        }
      }, 10_000);

      // cleanup on unmount
      return () => clearInterval(interval);
    }
  }, [image.id, image.status]);

  return (
    <div className={styles.imageCard}>
      {image.image_url && (
        <img
          src={image.image_url}
          alt={`Image ${image.id}`}
          className={styles.responsiveImage}
        />
      )}
      {['pending', 'in_progress'].includes(image.status) && (
        <div className={styles.spinnerContainer}>
          <div className={styles.spinner} />
        </div>
      )}
      <div className={styles.textBlock}>
        <div className={styles.status}>
          <span
            className={`${styles.statusPill} ${
              // image.status is one of "pending", "in_progress", "complete", "error"
              styles[image.status]
            }`}
          >
            {image.status?.replace('_', ' ')}
          </span>
        </div>
        <blockquote className={styles.prompt}>{image.prompt}</blockquote>
        <div className={styles.keywords}>
          {image.keywords.map((kw: string, i: number) => (
            <span key={i} className={styles.keywordPill}>
              {kw}
            </span>
          ))}
        </div>
      </div>
    </div>
  );
};

const App = () => {
  const [images, setImages] = useState<Image[]>([]);
  const [pagination, setPagination] = useState<Pagination>({
    total_count: 0,
    total_pages: 0,
    current_page: 1,
    per_page: 10
  });
  const [isLoading, setIsLoading] = useState(true);

  const fetchPage = async (page: number, perPage: number = pagination.per_page) => {
    setIsLoading(true);
    try {
      const { images, pagination: updatedPagination } = await client.getImages(page, perPage);
      setImages(images);
      setPagination(updatedPagination);
    } catch (e) {
      console.error(e);
    } finally {
      setIsLoading(false);
    }
  };

  useEffect(() => {
    fetchPage(1);
  }, []);

  const handlePrev = () => {
    if (pagination.current_page > 1) {
      fetchPage(pagination.current_page - 1);
    }
  };

  const handleNext = () => {
    if (pagination.current_page < pagination.total_pages) {
      fetchPage(pagination.current_page + 1);
    }
  };

  const setPage = (page: number) => {
    fetchPage(page);
  };

  const handlePerPageChange = (e:  ChangeEvent<HTMLSelectElement>) => {
    const { value } = e.target;
    fetchPage(1, Number(value));
  };

  const handlePostImage = async () => {
    try {
      const image = await client.createImage();

      setImages(images => [image, ...images]);
    } catch (error) {
      console.error('Error posting image:', error);
    }
  };

  return (
    <div className={styles.container}>
      <header className={styles.header}>
        <h1>AI Fart 🍑💨</h1>
        <nav className={styles.menu}>
          <button onClick={handlePostImage} className={styles.actionButton}>
            Fart 🍑💨
          </button>
        </nav>
      </header>

      <Navigation
        pagination={pagination}
        handlePrev={handlePrev}
        handleNext={handleNext}
        handlePerPageChange={handlePerPageChange}
        setPage={setPage}
      />

      {isLoading && (
        <div className={styles.spinnerContainer}>
          <div className={styles.spinner} />
        </div>
      )}

      <div className={styles.imageGrid}>
        {images.map((img, idx) => (
          <ImageContainer image={img} key={idx} onComplete={ () => fetchPage(1) } />
        ))}
      </div>

      <Navigation
        pagination={pagination}
        handlePrev={handlePrev}
        handleNext={handleNext}
        handlePerPageChange={handlePerPageChange}
        setPage={setPage}
      />
    </div>
  );
};

export default App;
