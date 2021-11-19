import csv


with open('eu_cities.csv') as csvfile:
    with open('eu_cities.toml', 'w') as tomlfile:
        reader = csv.reader(csvfile, delimiter=',', quotechar='"')
        for row in reader:
            tomlfile.write("[[groundstation]]\n")
            tomlfile.write("name = \"{}\"\n".format(row[1]))
            tomlfile.write("lat = {}\n".format(row[2]))
            tomlfile.write("long = {}\n".format(row[3]))
            tomlfile.write("\n")
            tomlfile.write("[groundstation.computeparams]\n")
            tomlfile.write("vcpu_count = 1\n")
            tomlfile.write("mem_size_mib = 512\n")
            tomlfile.write('rootfs = "client.img"\n')
            tomlfile.write("\n")