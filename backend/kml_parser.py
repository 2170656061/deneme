import xml.etree.ElementTree as ET
from typing import List, Tuple, Optional
import zipfile
import io

def parse_kml_content(content: bytes) -> Tuple[str, List[Tuple[float, float]]]:
    """
    Parse KML content and extract course name and checkpoint coordinates.
    
    Returns:
        Tuple of (course_name, [(latitude, longitude), ...])
    """
    try:
        root = ET.fromstring(content)
        
        # Define KML namespace
        ns = {'kml': 'http://www.opengis.net/kml/2.2'}
        
        # Extract folder/document name as course name
        document = root.find('.//kml:Document', ns)
        if document is None:
            document = root.find('.//kml:Folder', ns)
        
        course_name = "Imported Course"
        if document is not None:
            name_elem = document.find('kml:name', ns)
            if name_elem is not None and name_elem.text:
                course_name = name_elem.text
        
        # Extract all placemarks and their coordinates
        placemarks = root.findall('.//kml:Placemark', ns)
        coordinates = []
        
        for placemark in placemarks:
            # Try Point
            point = placemark.find('kml:Point/kml:coordinates', ns)
            if point is not None and point.text:
                coords = parse_coordinates(point.text)
                if coords:
                    coordinates.extend(coords)
            
            # Try LineString
            linestring = placemark.find('kml:LineString/kml:coordinates', ns)
            if linestring is not None and linestring.text:
                coords = parse_coordinates(linestring.text)
                if coords:
                    coordinates.extend(coords)
            
            # Try MultiGeometry
            geometries = placemark.findall('kml:MultiGeometry//kml:Point/kml:coordinates', ns)
            for geom in geometries:
                if geom.text:
                    coords = parse_coordinates(geom.text)
                    if coords:
                        coordinates.extend(coords)
        
        return course_name, coordinates
    
    except ET.ParseError as e:
        raise ValueError(f"Invalid KML format: {str(e)}")


def parse_coordinates(coord_text: str) -> List[Tuple[float, float]]:
    """
    Parse KML coordinates string and return list of (latitude, longitude) tuples.
    KML format is: longitude,latitude[,altitude] longitude,latitude[,altitude] ...
    """
    coordinates = []
    
    # Split by whitespace and parse each coordinate
    coord_pairs = coord_text.strip().split()
    
    for pair in coord_pairs:
        parts = pair.split(',')
        if len(parts) >= 2:
            try:
                lon = float(parts[0])
                lat = float(parts[1])
                coordinates.append((lat, lon))  # Return as (lat, lon)
            except ValueError:
                continue
    
    return coordinates


def extract_kmz(content: bytes) -> bytes:
    """
    Extract KML from KMZ (zipped KML) file.
    """
    try:
        with zipfile.ZipFile(io.BytesIO(content)) as kmz:
            # Find the .kml file in the archive
            for file_info in kmz.filelist:
                if file_info.filename.endswith('.kml'):
                    return kmz.read(file_info.filename)
        raise ValueError("No KML file found in KMZ archive")
    except zipfile.BadZipFile:
        raise ValueError("Invalid KMZ file format")


def process_kml_file(filename: str, content: bytes) -> Tuple[str, List[Tuple[float, float]]]:
    """
    Process KML or KMZ file and extract course data.
    """
    if filename.endswith('.kmz'):
        kml_content = extract_kmz(content)
        return parse_kml_content(kml_content)
    elif filename.endswith('.kml'):
        return parse_kml_content(content)
    else:
        raise ValueError("File must be KML or KMZ format")
