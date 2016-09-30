import os
import exifread


def output(file, f_dir, f_name, f_format):
    try:
        open(f_dir + f_name + '.' + f_format)
        os.renames(file, f_dir + f_name + '.copy.' + f_format)
    except:
        os.renames(file, f_dir + f_name + '.' + f_format)


def getexif(filename):
    file = open(filename, 'rb')
    try:
        tags = exifread.process_file(file)
        dtime = str(tags.get('Image datetime'))
        if dtime == 'None':
            raise Exception
        file.close()
        return dtime[:4], dtime.replace(':', '').replace(' ', '_')
    except:
        file.close()
        return None, None


class Photo:
    def __init__(self, input_dir, output_dir):
        self.input_dir = input_dir
        self.output_dir = output_dir
        self.files = self.getfilelist()
        self.process()
    
    def getfilelist(self):
        filelist = []
        for row in os.walk(top=self.input_dir):
            if row[2]:
                for file in row[2]:
                    filelist.append(row[0] + '/' + file)
        return filelist
    
    def process(self):
        for file in self.files:
            file_array = file.split('.')
            format_file = file_array[len(file_array) - 1].lower()
            
            if format_file in ('jpg', 'jpeg', 'png', 'gif'):
                self.image_file(file)
            elif format_file in ('mov', 'mp4', 'm4v'):
                self.video_file(file)
            else:
                self.unknown_file(file)

    def image_file(self, file):
        file_temp = file.split('/')
        file_format = file_temp[len(file_temp) - 1].split('.')
        year, filename = getexif(file)
        if year == "None":
            output(file, self.output_dir + 'Images/NoEXIF/',
                   file_format[0], file_format[1])
        else:
            try:
                output(file, self.output_dir + 'Images/' + year + '/',
                       filename, file_format[1])
            except:
                output(file, self.output_dir + 'Images/NoEXIF/',
                       file_format[0], file_format[1])
    
    def video_file(self, file):
        file_temp = file.split('/')
        file_format = file_temp[len(file_temp) - 1].split('.')
        output(file, self.output_dir + 'Video/',
               file_format[0].upper(), file_format[1].lower())
    
    def unknown_file(self, file):
        file_temp = file.split('/')
        file_format = file_temp[len(file_temp) - 1].split('.')
        if len(file_format) != 2:
            file_format.append('unknown')
        output(file, self.output_dir + 'Unknown/',
               file_format[0].upper(), file_format[1].lower())


if __name__ == '__main__':
    photo = Photo(input_dir='/Volumes/Test/Import/',
                  output_dir='/Volumes/Test/Export/')
