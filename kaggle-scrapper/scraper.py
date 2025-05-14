import datetime
import logging
import os
import re
from concurrent.futures import ThreadPoolExecutor, as_completed

import psycopg2
from selenium import webdriver
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.common.by import By
from selenium.webdriver.support import expected_conditions
from selenium.webdriver.support.wait import WebDriverWait

logger = logging.getLogger(__name__)

SELENIUM_URL = os.getenv("SELENIUM_URL", "http://localhost:4444/wd/hub")
DB_CONNECTION_URL = os.getenv("DB_CONNECTION_URL", "postgresql://postgres:password@localhost:4819/postgres")
DB_CONNECTION = psycopg2.connect(DB_CONNECTION_URL)
DB_CURSOR = DB_CONNECTION.cursor()
KAGGLE_DATASETS_PAGE_URL = "https://www.kaggle.com/datasets?page={}"

PAGE_START = 2
PAGE_END = 500  # https://github.com/Kaggle/kaggle-api/issues/553


def is_processed(dataset_href):
  DB_CURSOR.execute(
    "SELECT 1 FROM datasets WHERE dataset_ref = %s LIMIT 1",
    (dataset_href,),
  )
  return DB_CURSOR.fetchone()


def process_new_dataset(
    author_id, author_name, dataset_title, dataset_ref, dataset_size, file_count, source_type, usability):
  if is_processed(dataset_ref):
    logger.info("Dataset '%s' already processed", dataset_ref)
    return

  created_at = datetime.datetime.now(datetime.timezone.utc)
  updated_at = datetime.datetime.now(datetime.timezone.utc)

  DB_CURSOR.execute(
    """
    INSERT INTO datasets (
        author_id, author_name, dataset_title, dataset_ref, dataset_size, 
        file_count, file_types, usability, created_at, updated_at
    ) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
    """,
    (
      author_id, author_name, dataset_title, dataset_ref, dataset_size,
      file_count, source_type, usability, created_at, updated_at
    )
  )
  DB_CONNECTION.commit()


def parse(text):
  pattern = r"Usability (\d+.\d+) · (\d+) Files? \((.+)\) · ([^.]+)"

  match = re.search(pattern, text)

  if match:
    usability = match.group(1)
    file_count = match.group(2)
    source_type = match.group(3)
    dataset_size = match.group(4)
    return (float(usability), int(file_count), str(source_type), str(dataset_size))

  pattern_without_file_count = r"Usability (\d+.\d+) · ([^.]+)"
  match_without_file_count = re.search(pattern_without_file_count, text)
  if match_without_file_count:
    usability = match_without_file_count.group(1)
    dataset_size = match_without_file_count.group(2)
    return (str(usability), None, None, dataset_size)

  return None


def run_scrapper(url_and_range):
  try:
    url, page_range = url_and_range

    chrome_options = Options()
    # chrome_options.add_argument("--headless")
    chrome_options.add_argument("--no-sandbox")
    chrome_options.add_argument("--disable-dev-shm-usage")
    chrome_options.set_capability("browserVersion", "115.0")
    chrome_options.set_capability("browserName", "chrome")

    driver = webdriver.Remote(
      command_executor=url,
      options=chrome_options,
    )

    for page in page_range:
      logger.info("---" * 5 + " " + str(page) + " " + "---" * 5)

      driver.get(KAGGLE_DATASETS_PAGE_URL.format(page))

      author_names_xpath = "/html/body/div[1]/div[3]/div[2]/div[5]/div/div/div/ul[1]/li[*]/div/a/div/div[2]/span[1]/a"
      dataset_titles_xpath = "/html/body/div[1]/div[3]/div[2]/div[5]/div/div/div/ul[1]/li[*]/div/a/div/div[2]/div"
      dataset_links_xpath = "/html/body/div[1]/div[3]/div[2]/div[5]/div/div/div/ul[1]/li[*]/div/a"
      dataset_meta_xpath = "/html/body/div[1]/div[3]/div[2]/div[5]/div/div/div/ul[1]/li[*]/div/a/div/div[2]/span[2]"
      WebDriverWait(driver, 10).until(
        expected_conditions.presence_of_element_located((By.XPATH, dataset_links_xpath))
      )

      author_names_xpath = driver.find_elements(By.XPATH, author_names_xpath)
      dataset_title_elements = driver.find_elements(By.XPATH, dataset_titles_xpath)
      dataset_href_elements = driver.find_elements(By.XPATH, dataset_links_xpath)
      dataset_meta_elements = driver.find_elements(By.XPATH, dataset_meta_xpath)
      for author_name_el, dataset_title_el, dataset_href_el, dataset_meta_el in (
          zip(author_names_xpath, dataset_title_elements, dataset_href_elements, dataset_meta_elements)
      ):
        dataset_href = dataset_href_el.get_attribute("href")
        logger.info(dataset_href)

        author_id = author_name_el.get_attribute("href").removeprefix("https://www.kaggle.com/")
        author_name = author_name_el.text
        dataset_title = dataset_title_el.text
        dataset_ref = dataset_href.removeprefix("https://www.kaggle.com/datasets/")
        dataset_metadata = parse(dataset_meta_el.text)
        if dataset_metadata is None:
          logger.info("Something wrong with dataset '%s'", dataset_ref)
          continue

        usability, file_count, source_type, dataset_size = dataset_metadata
        process_new_dataset(
          author_id=author_id,
          author_name=author_name,
          dataset_title=dataset_title,
          dataset_ref=dataset_ref,
          dataset_size=dataset_size,
          file_count=file_count,
          source_type=source_type,
          usability=usability)
    driver.quit()
  except Exception as e:
    logger.error("[SCRAPPED ERROR] '%s'", e)


def main():
  logging.basicConfig(format="%(asctime)s - %(levelname)s", level=logging.INFO)

  total_range = list(range(PAGE_START, PAGE_END + 1))

  num_threads = 1
  chunk_size = len(total_range) // num_threads
  chunks = [total_range[i * chunk_size: (i + 1) * chunk_size] for i in range(num_threads)]

  if len(total_range) % num_threads != 0:
    chunks[-1].extend(total_range[num_threads * chunk_size:])

  with ThreadPoolExecutor(max_workers=num_threads) as executor:
    futures = [
      executor.submit(run_scrapper, (SELENIUM_URL, chunk))
      for chunk in chunks
    ]
    for future in as_completed(futures):
      try:
        future.result()
      except Exception as e:
        print(f"Ошибка в потоке: {e}")


if __name__ == "__main__":
  main()
