from csv import reader
from typing import List
from datetime import datetime
from domain.accelerometer import Accelerometer
from domain.gps import Gps
from domain.aggregated_data import AggregatedData
from domain.parking import Parking


class FileDatasource:
    def __init__(self, accelerometer_filename: str, gps_filename: str, parking_filename: str) -> None:
        self.accelerometer_filename = accelerometer_filename
        self.gps_filename = gps_filename
        self.parking_filename = parking_filename
        pass

    def read(self) -> List[AggregatedData]:
        dataList = []
        for i in range(13):
            parking_data = next(self.parking_data_reader)
            dataList.append(
                AggregatedData(
                    Accelerometer(*next(self.accelerometer_data_reader)),
                    Gps(*next(self.gps_data_reader)),
                    Parking(parking_data[0], parking_data[1:]),
                    datetime.now()
                )
            )
        return dataList

    def file_data_reader(self, path: str):
        while True:
            file = open(path)
            data_reader = reader(file)
            next(data_reader)
            for row in data_reader:
                yield row
            file.close()

    def startReading(self, *args, **kwargs):
        self.accelerometer_data_reader = self.file_data_reader(self.accelerometer_filename)
        self.gps_data_reader = self.file_data_reader(self.gps_filename)
        self.parking_data_reader = self.file_data_reader(self.parking_filename)

    def stopReading(self, *args, **kwargs):
        pass