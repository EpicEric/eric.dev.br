---
title: Geohash-based clustering for GeoDjango points
s: geohash-cluster
tags:
---
To-do:
* Previous attempts with manual SQL PostGIS approaches (DBScan, ClusterWithin, tiles)
* What is geohash
* Adding geohash to queries with native GeoDjango code
* Cluster-specific model for persistence cases (+ custom manager, API endpoint)
* Integration with front-end clustering

```python
from functools import reduce

from django.contrib.gis.db import models
from django.contrib.gis.db.models import Collect, Count, F
from django.contrib.gis.db.models.functions import Centroid, GeoHash
from django.contrib.gis.geos import Point

from django.db.models.functions import Substr

from base_station.models import IdentifiedBaseStation

BS_MODEL = IdentifiedBaseStation

MAX_CLUSTER_ZOOM_SIZE = 16

ZOOM_TO_GEOHASH_PRECISION = {
    0: 1,
    1: 2,
    2: 2,
    3: 2,
    4: 3,
    5: 3,
    6: 4,
    7: 4,
    8: 4,
    9: 5,
    10: 5,
    11: 6,
    12: 6,
    13: 6,
    14: 7,
    15: 7,
    16: 7,
}

MAX_CLUSTER_PRECISION_SIZE = ZOOM_TO_GEOHASH_PRECISION[MAX_CLUSTER_ZOOM_SIZE]


class ClusterManager(models.Manager):
    def get_queryset(self):
        return super(ClusterManager, self).get_queryset()\
            .annotate(geohash=GeoHash('point', precision=F('precision')))


class BaseStationCluster(models.Model):
    point = models.PointField()
    precision = models.PositiveIntegerField()
    count = models.PositiveIntegerField()
    data = models.CharField(max_length=40, blank=True)

    objects = ClusterManager()  # Annotates 'geohash' field on queryset objects

    def __str__(self):
        if self.count == 1:
            return "{} ({})".format(self.point, self.data)
        return "{} ({} stations)".format(self.point, self.count)

    @property
    def base_stations(self):
        return BS_MODEL.objects.annotate(geohash=GeoHash('point', precision=self.precision))\
            .filter(geohash__eq=self.geohash)

    @classmethod
    def generate_clusters(cls, precision):
        if not cls.objects.filter(precision=precision).exists():
            # Generate clusters from smaller clusters
            if 1 <= precision < MAX_CLUSTER_PRECISION_SIZE:
                print('Generating clusters...')
                # Get smaller clusters and annotate the new geohash for the bigger clusters
                smaller_precision = precision + 1
                smaller_clusters = cls.objects.filter(precision=smaller_precision)\
                    .annotate(bigger_geohash=Substr('geohash', 1, precision))
                # Group by bigger geohash
                clusters_hashes = smaller_clusters.values('bigger_geohash').distinct()
                total = clusters_hashes.count()
                if not total:
                    raise ValueError('No clusters found for precision {}'.format(precision + 1))
                print('Saving data for {} clusters...'.format(total - loop_counter))
                loop_counter = 0
                percentage = 0
                for cluster_dict in clusters_hashes:
                    geohash = cluster_dict['bigger_geohash']
                    # Exclude values for clusters that already exist
                    if cls.filter(geohash=geohash).exists():
                        continue
                    # Get data from smaller clusters
                    sub_clusters = smaller_clusters.filter(bigger_geohash=geohash).values('point', 'count')
                    count = reduce((lambda acc, cl: acc + cl['count']), sub_clusters, 0)
                    point = Point(
                        reduce((lambda acc, cl: acc + (cl['point'].x * float(cl['count']))), sub_clusters, 0.0)
                        / float(count),
                        reduce((lambda acc, cl: acc + (cl['point'].y * float(cl['count']))), sub_clusters, 0.0)
                        / float(count)
                    )
                    data = '' if count != 1 else sub_clusters[0].data
                    cluster = cls(point=point, precision=precision, count=count, data=data)
                    cluster.save()
                    loop_counter += 1
                    prev_percentage = percentage
                    percentage = 100 * loop_counter // total
                    if percentage > prev_percentage:
                        print(' {}% done ({} clusters)'.format(percentage, loop_counter))

            # Generate clusters from base stations
            elif precision == MAX_CLUSTER_PRECISION_SIZE:
                print("Generating clusters...")
                # Add geohash to all base stations
                base_stations = BS_MODEL.objects.annotate(geohash=GeoHash('point', precision=precision))
                # Group by geohash and get cluster MultiPoint and count
                clusters_values = base_stations.values('geohash').annotate(count=Count('point'), geom=Centroid(Collect('point')))
                total = clusters_values.count()
                if not total:
                    raise ValueError('No base stations found for precision {}'.format(precision))
                print('Saving data for {} clusters...'.format(total))
                loop_counter = 0
                percentage = 0
                for cluster_dict in clusters_values:
                    loop_counter += 1
                    # Exclude values for clusters that already exist
                    if cls.filter(geohash=cluster_dict['geohash']).exists():
                        continue
                    count = cluster_dict['count']
                    point = cluster_dict['geom']
                    data = '' if count != 1 else base_stations.get(geohash=cluster_dict['geohash']).data
                    cluster = cls(point=point, precision=precision, count=count, data=data)
                    cluster.save()
                    prev_percentage = percentage
                    percentage = 100 * loop_counter // total
                    if percentage > prev_percentage:
                        print(' {}% done ({} clusters)'.format(percentage, loop_counter))

            else:
                raise ValueError('precision must be in the [1, {}] interval'.format(MAX_CLUSTER_PRECISION_SIZE))

        else:
            raise ValueError('There are already clusters for precision {}'.format(precision))

    @classmethod
    def get_clusters_for_zoom(cls, zoom_size):
        return cls.objects.filter(precision=ZOOM_TO_GEOHASH_PRECISION[zoom_size])
```
