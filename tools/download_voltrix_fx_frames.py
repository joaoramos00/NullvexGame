import urllib.request
import sys

def download(base_url_template, count, out_prefix):
    for i in range(count):
        url = base_url_template.format(i=i)
        req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
        with urllib.request.urlopen(req, timeout=30) as r:
            data = r.read()
        out_path = f"{out_prefix}_f{i:02d}.png"
        with open(out_path, "wb") as f:
            f.write(data)
        print("saved", out_path)

if __name__ == "__main__":
    template = sys.argv[1]
    count = int(sys.argv[2])
    out_prefix = sys.argv[3]
    download(template, count, out_prefix)
