import argparse

from script import *

def create(**kwargs):

    folder = kwargs.pop('folder')
    create_rts_MATPOWER_file(folder)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Create RTS MATPOWER file.')
    parser.add_argument('--folder', dest='folder', default='../../SourceData',
                       help='source data folder path')

    args = parser.parse_args()

    # todo : check if folder exists
    create(folder = args.folder)

