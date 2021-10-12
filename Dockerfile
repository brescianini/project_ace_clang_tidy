FROM project_ace:galactic

COPY entrypoint.sh /entrypoint.sh
COPY run-clang-tidy.py /run-clang-tidy.py

ENTRYPOINT ["/entrypoint.sh"]
