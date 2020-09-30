#! /bin/sh
# This is the code used to train and test a transliteration model on the data provided, i.e. the mined hindi-english pairs. 
# Step 1: We will install all libraries and packages required to run moses.

sudo apt-get install g++ git subversion automake libtool zlib1g-dev libicu-dev libboost-all-dev libbz2-dev liblzma-dev python-dev graphviz  imagemagick make cmake libgoogle-perftools-dev autoconf doxygen

# Step 2: Repository of moses is cloned in the root directory.

git clone https://github.com/moses-smt/mosesdecoder.git
cd mosesdecoder

#Step 3: Downloading boost in the mosesdecoder directory and extracting the tar.gz file

wget http://downloads.sourceforge.net/project/boost/boost/1.55.0/boost_1_66_0.tar.gz
tar zxvf boost_1_66_0.tar.gz
cd boost_1_66_0/
./bootstrap.sh
./b2 -j5 --prefix=$PWD --libdir=$PWD/lib64 --layout=system link=static install || echo FAILURE

#Step 4: Downloading and Installing CMPH2.0 in the mosesdecoder directory

cd ..
wget http://www.achrafothman.net/aslsmt/tools/cmph_2.0.orig.tar.gz
tar zxvf cmph_2.0.orig.tar.gz
cd cmph-2.0/
./configure
make
sudo make install
sudo make installcheck


#Step 5: Using Boost and CMPH moses is compiled.

./bjam –with-boost=./boost_1_66_0 –with-cmph=./cmph-2.0 -a -j5

#Step 6: Cloning and  Installing GIZA++  in the root directory

cd ..
git clone https://github.com/moses-smt/giza-pp.git
cd giza-pp
make

# Creating binaries ~/giza-pp/GIZA++-v2/GIZA++, ~/giza-pp/GIZA++-v2/snt2cooc.out and ~/giza-pp/mkcls-v2/mkcls. 
#These binaries should be accesible to moses

cd ~/mosesdecoder
mkdir tools
cp ~/giza-pp/GIZA++-v2/GIZA++ ~/giza-pp/GIZA++-v2/snt2cooc.out ~/giza-pp/mkcls-v2/mkclstools


#Step 7: Corpus Creation - already present in the root directory

#Step 8: Training of Language model

cd
mkdir lm1
cd lm1
~/mosesdecoder/bin/lmplz -o 3 <~/corpus/train1.en > arpa.en --discount_fallback

#Discount fallback is involved to avoid error as a small training data is there

#Creation of an arpa file in the lm1 folder.

~/mosesdecoder/bin/build_binary arpa.en blm.en

#This should create a blm.en file in the lm1 folder. 

#Step 10: Training of translation model in a directory present in the root directory.

cd
mkdir working1
cd working1
nohup nice /home/ubuntu/mosesdecoder/scripts/training/train-model.perl -root-dir /home/ubuntu/working1/train -corpus /home/ubuntu/corpus/train1 -f hi -e en -alignment grow-diag-final-and -reordering msd-bidirectional-fe -lm 0:3:/home/ubuntu/lm1/blm.en:8 -external-bin-dir ~/mosesdecoder/tools >& training.out &

#a moses.ini file is created in the directory ~/working/train/model after the program execution
#The ~/working/train directory contains corpus, giza.en-hi, giza.hi-en and model.
#The corpus contains multiple files en.vcb, en.vcb.classes, en.vcb.classes.cats, en-hi-int-train.snt, hi.vcb, hi.vcb.classes, hi.vcb.classes.cats and hi-en-int-train.snt

#Step 11: Testing

nohup nice ~/mosesdecoder/bin/moses -f ~/working1/train/model/moses.ini < ~/corpus/test1.hi > ~/working1/test1.translated.en 2> ~/working1/testing.out

#Creation of a names test1.translated.en file in the working directory. 
#Transliterated words can be seen in test1.translated.en file.

#Step 12: Calculating the BLEU score:

/home/ubuntu/mosesdecoder/scripts/generic/multi-bleu.perl -lc /home/ubuntu/corpus/test1.en < /home/ubuntu/working1/test1.translated.en

#Comparison of files test1.en and test1.translated.en
#Calculation of BLEU score





























