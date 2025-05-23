

```bash
docker run -it --rm conda/miniconda3
conda install -y -c conda-forge conda-build
conda install -y git
git clone https://github.com/bgruening/conda_r_skeleton_helper.git
cd conda_r_skeleton_helper/
echo 'r-interprocess' > packages.txt
echo '    - dansmith01' >> extra.yaml
./run.sh
```


If compiling, add `    - {{ stdlib('c') }}` under `requirements:  build:`.
