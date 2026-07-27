import logging
import os
import sys
from automation.config.config import Config

class TestLogger:
    _logger = None

    @classmethod
    def get_logger(cls):
        if cls._logger is None:
            Config.ensure_directories()
            log_file = os.path.join(Config.LOGS_DIR, "execution.log")

            logger = logging.getLogger("PostureFixPro_Automation")
            logger.setLevel(logging.INFO)
            logger.handlers = []

            # File handler
            fh = logging.FileHandler(log_file, mode='w', encoding='utf-8')
            fh.setLevel(logging.INFO)

            # Console handler
            ch = logging.StreamHandler(sys.stdout)
            ch.setLevel(logging.INFO)

            # Formatter
            formatter = logging.Formatter('[%(asctime)s] [%(levelname)s] [%(filename)s:%(lineno)d] - %(message)s')
            fh.setFormatter(formatter)
            ch.setFormatter(formatter)

            logger.addHandler(fh)
            logger.addHandler(ch)
            cls._logger = logger

        return cls._logger
