import os
from pathlib import Path
from typing import Dict, List, Tuple

from wizard import downloader, io, ux


class ArchiveUrls:
    def __init__(self, begin_url: str, end_url: str) -> None:
        self.begin_url = begin_url
        self.end_url = end_url


class ImportDbArchivesController:
    def __init__(self,
                 workspace: Path,
                 network: str,
                 shards: List[str],
                 num_parallel_downloads: int) -> None:
        self.workspace = workspace
        self.network = network
        self.shards = shards
        self.num_parallel_downloads = num_parallel_downloads
        self.urls: Dict[str, ArchiveUrls] = dict()

        self.downloads_folder = io.get_downloads_path(self.workspace)

    def download(self):
        self.downloads_folder.mkdir(parents=True, exist_ok=True)

        # Gather desired URLs (ask for them, when appropriate)
        for shard in self.shards:
            begin_url = ""
            end_url = ""

            if self.should_download_archive_of_begin(shard):
                begin_url = ux.ask_input_string(f"URL of public archive to download, as *beginning* of history, for shard {shard}")
            if self.should_download_archive_of_end(shard):
                end_url = ux.ask_input_string(f"URL of *latest* public archive to download, for shard {shard}")

            self.urls[shard] = ArchiveUrls(begin_url, end_url)

        # Perform the actual downloads
        download_tasks: List[Tuple[str, Path]] = []
        for shard, urls in self.urls.items():
            if urls.begin_url:
                filepath = self.downloads_folder / f"{self.network}-{shard}-begin.archive"
                download_tasks.append((urls.begin_url, filepath))
            if urls.end_url:
                filepath = self.downloads_folder / f"{self.network}-{shard}-end.archive"
                download_tasks.append((urls.begin_url, filepath))

        downloader.download_files(download_tasks, self.num_parallel_downloads)

    def should_download_archive_of_begin(self, shard: str):
        return not self.is_archive_ready_in_db(shard) and not self.is_archive_downloaded(f"{self.network}-{shard}-begin")

    def should_download_archive_of_end(self, shard: str):
        return not self.is_archive_ready_in_import_db(shard) and not self.is_archive_downloaded(f"{self.network}-{shard}-end")

    def is_archive_downloaded(self, name: str):
        files = list(self.downloads_folder.rglob(name))
        return len(files) == 1

    def is_archive_ready_in_import_db(self, shard: str):
        folder = io.get_node_import_db_path(self.workspace, self.network, shard)
        return len(os.listdir(folder)) > 0

    def is_archive_ready_in_db(self, shard: str):
        folder = io.get_node_db_path(self.workspace, self.network, shard)
        return len(os.listdir(folder)) > 0

    def extract(self):
        pass

    def cleanup(self):
        pass
