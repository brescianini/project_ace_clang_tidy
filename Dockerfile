FROM 105629644892.dkr.ecr.ap-northeast-1.amazonaws.com/sai-project-ace:focal-cuda11.3-galactic

COPY entrypoint.sh /entrypoint.sh
COPY run-clang-tidy.py /run-clang-tidy.py

ENTRYPOINT ["/entrypoint.sh"]
