import argparse
import COAD
import pandas as pds

def get_region_zone(xml, gen, get_zone=True):
    """Returns region and zone for generator object

    This code assumes that all generators are tied to a node and that nodes 
    are tied to regions and zones. If this is not the case, code needs to be updated
    
    Arguments:
        xml {COAD database} -- xml database for querying
        gen {string} -- name of generator
    Returns:
        region {string} -- name of region
        zone {string} -- name of zone
    """ 

    # get node of generator
    node = xml['Generator'][gen].get_children('Node')
    # Use node to get region and zone mapping
    region = node[0].get_children('Region')[0].meta['name']
    if get_zone and node[0].get_children('Zone'):
        zone = node[0].get_children('Zone')[0].meta['name']
    else:
        zone = ''

    return (region,zone)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(formatter_class=argparse.RawTextHelpFormatter,
        description="Create Excel file with Objects to add to PLEXOS model.")
    parser.add_argument("xml_file", 
        help="Path to PLEXOS model (in XML format) to grab\n" + \
             "generator region-zone mapping from.")
    parser.add_argument("output_file", default='gen_region_zone.csv',
        help="Full path file name of output file.")
    parser.add_argument("-z","--no_zones",action="store_false",
        help="Don't return zones, only regions")

    args = parser.parse_args()

    # Process input data base with COAD and get region-zone mapping
    xml_data = COAD.COAD(args.xml_file)
    generators = xml_data['Generator'].keys()
    mapping = {x:get_region_zone(xml_data,x,args.no_zones) for x in generators}

    # Put into pandas data frame and write to csv
    df = pds.DataFrame(mapping.items())
    df[['region','zone']] = df[1].apply(pds.Series)
    del(df[1])
    df.columns = ['name','Region','Zone']

    df.to_csv(args.output_file, index=False)
