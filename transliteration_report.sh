#! /bin/sh
# This is the code used to train and test a transliteration model on the data provided, i.e. the mined hindi-english pairs. 
# Step 1: We will install all libraries and packages required to run moses.

sudo apt-get install g++ git subversion automake libtool zlib1g-dev libicu-dev libboost-all-dev libbz2-dev liblzma-dev python-dev graphviz  imagemagick make cmake libgoogle-perftools-dev autoconf doxygen

# Step 2: Cloning moses from git. I worked in my HOME folder, but you can create a new folder for this. 

git clone https://github.com/moses-smt/mosesdecoder.git
cd mosesdecoder

#Step 3: Installing Boost inside the mosesdecoder directory

wget http://downloads.sourceforge.net/project/boost/boost/1.55.0/boost_1_66_0.tar.gz
tar zxvf boost_1_66_0.tar.gz
cd boost_1_66_0/
./bootstrap.sh
./b2 -j5 --prefix=$PWD --libdir=$PWD/lib64 --layout=system link=static install || echo FAILURE

# going back to the mosesdecoder directory

cd ..

#Step 4: Installing CMPH2.0 (also in the mosesdecoder directory)

wget http://www.achrafothman.net/aslsmt/tools/cmph_2.0.orig.tar.gz
tar zxvf cmph_2.0.orig.tar.gz
cd cmph-2.0/
./configure
make
sudo make install
sudo make installcheck


#Step 5: Compiling moses with Boost and CMPH

./bjam –with-boost=./boost_1_66_0 –with-cmph=./cmph-2.0 -a -j5

#Step 6: Installing GIZA++ (int the HOME directory)

cd ..
git clone https://github.com/moses-smt/giza-pp.git
cd giza-pp
make

# This creates the binaries ~/giza-pp/GIZA++-v2/GIZA++, ~/giza-pp/GIZA++-v2/snt2cooc.out and ~/giza-pp/mkcls-v2/mkcls. These need to be copied to somewhere that Moses can find them. We create a new directory in the mosesdecoder folder named tools and copy these files in that directory

cd ~/mosesdecoder
mkdir tools
cp ~/giza-pp/GIZA++-v2/GIZA++ ~/giza-pp/GIZA++-v2/snt2cooc.out ~/giza-pp/mkcls-v2/mkclstools


#Step 7: Creating a corpus directory (in the HOME directory)

cd
mkdir corpus

#Step 8: Saving the necessary test and train files in the corpus. This was done manually and the data set was processed using Jupyter Notebook. The corpus contains 4 files namely train1.hi, train1.en, test1.hi and test1.en. 

#Step 9: Language model training (in the HOME directory)

cd
mkdir lm1
cd lm1
~/mosesdecoder/bin/lmplz -o 3 <~/corpus/train1.en > arpa.en --discount_fallback

# The --discount_fallback is used because the data we are training is a small artificial data and if --discount_fallback is not used, then we get a BadDiscountException error.

#This creates an arpa file in the lm1 folder. 
#To binarize the arpa file, using kenLM:

~/mosesdecoder/bin/build_binary arpa.en blm.en

#This should create a blm.en file in the lm1 folder. 

#Step 10: Training the translation system, after creating a directory working in the HOME directory. 

cd
mkdir working1
cd working1
nohup nice $HOME/mosesdecoder/scripts/training/train-model.perl -root-dir $HOME/working1/train -corpus $HOME/corpus/train1 -f hi -e en -alignment grow-diag-final-and -reordering msd-bidirectional-fe -lm 0:3:$HOME/lm1/blm.en:8 -external-bin-dir ~/mosesdecoder/tools >& training.out &

#This takes a little time. Once this command finishes running, you should see a moses.ini file in the directory ~/working1/train/model

#The train directory in the working1 directory also contains corpus, giza.en-hi, giza.hi-en and model. 

#The corpus contains multiple files en.vcb, en.vcb.classes, en.vcb.classes.cats, en-hi-int-train.snt, hi.vcb, hi.vcb.classes, hi.vcb.classes.cats and hi-en-int-train.snt

#After this, we skip the process of tuning data (that requires a small amount of parallel data, seperate from the training and test data)

#Step 11: Testing


nohup nice ~/mosesdecoder/bin/moses -f ~/working1/train/model/moses.ini < ~/corpus/test1.hi > ~/working1/test1.translated.en 2> ~/working1/testing.out

#This creates a file names test1.translated.en file in the working1 directory. The command takes a little time and when finished, you can open the test1.translated.en file and see the transliterated words. 

#Step 12: Calculating the BLEU score:

$HOME/mosesdecoder/scripts/generic/multi-bleu.perl -lc $HOME/corpus/test1.en < $HOME/working1/test1.translated.en

#This command compares the files test1.en and test1.translated.en and calculates the BLEU score. 
#I got a score of 61.34, which corresponds to a score of 0.6134.




























