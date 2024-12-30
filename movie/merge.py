from pathlib import Path

import cv2


def merge(dir: Path = Path("."), out_path: Path = Path("pathfinding.mp4")):
    files = sorted(dir.glob("*.png"), key=lambda x: int(x.stem))

    writer = cv2.VideoWriter(
        str(out_path), cv2.VideoWriter_fourcc(*"mp4v"), 30, (400, 400), isColor=True
    )
    for f in files:
        img = cv2.imread(str(f))
        writer.write(cv2.resize(img, (400, 400), interpolation=cv2.INTER_NEAREST_EXACT))
    writer.release()


if __name__ == "__main__":
    merge()
