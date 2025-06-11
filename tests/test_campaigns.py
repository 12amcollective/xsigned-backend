import unittest
from src.models.campaign import Campaign
from src.services.campaign_service import CampaignService

class TestCampaignService(unittest.TestCase):

    def setUp(self):
        self.campaign_service = CampaignService()

    def test_create_campaign(self):
        campaign_data = {
            'name': 'Summer Music Festival',
            'status': 'active'
        }
        campaign = self.campaign_service.create_campaign(campaign_data)
        self.assertIsNotNone(campaign.id)
        self.assertEqual(campaign.name, campaign_data['name'])
        self.assertEqual(campaign.status, campaign_data['status'])

    def test_get_campaign(self):
        campaign_data = {
            'name': 'Winter Music Festival',
            'status': 'inactive'
        }
        campaign = self.campaign_service.create_campaign(campaign_data)
        fetched_campaign = self.campaign_service.get_campaign(campaign.id)
        self.assertEqual(fetched_campaign.name, campaign_data['name'])
        self.assertEqual(fetched_campaign.status, campaign_data['status'])

    def test_update_campaign_progress(self):
        campaign_data = {
            'name': 'Spring Music Festival',
            'status': 'active'
        }
        campaign = self.campaign_service.create_campaign(campaign_data)
        self.campaign_service.update_campaign_progress(campaign.id, '50%')
        updated_campaign = self.campaign_service.get_campaign(campaign.id)
        self.assertEqual(updated_campaign.progress, '50%')

if __name__ == '__main__':
    unittest.main()