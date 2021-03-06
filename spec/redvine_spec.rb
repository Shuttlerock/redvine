require 'redvine'
require 'spec_helper'
require 'vcr_setup'

include Helpers

describe Redvine do

  it "should require connecting before accessing other API methods" do
    config = get_config
    client = Redvine.new
    expect { client.search('cat') }.to raise_error(Redvine::AuthenticationRequiredError)
  end

  describe '.connect' do

    let(:config) { get_config() }
    let(:client) { Redvine.new }

    it 'should create a new client' do
      expect(client).to respond_to(:connect).with(1).argument
    end

    it 'should raise an error without a username and password' do
      expect { client.connect() }.to raise_error(ArgumentError)
    end

    it 'should connect and return a hash with a :vine_key' do
      VCR.use_cassette('redvine') do
        client.connect(email: config['email'], password: config['password'])
        expect(client.vine_key).to be_an_instance_of(String)
      end
    end

    it 'should raise a specific error if username/password is incorrect' do
      VCR.use_cassette('redvine_error') do
        expect { client.connect(email: 'fake_email@someplace.net', password: 'nope1nope2nope3') }.to raise_error(Redvine::ConnectionError)
      end
    end

    it 'should extract error code and message if username/password is incorrect' do
      VCR.use_cassette('redvine_error') do
        begin
          client.connect(email: 'fake_email@someplace.net', password: 'nope1nope2nope3')
        rescue Redvine::ConnectionError => e
          expect(e.code).to be_an_instance_of(Fixnum)
          expect(e.code).to be > 0
          expect(e.message).to be_an_instance_of(String)
        end
      end
    end

    it 'should not raise if passed skip_exception when username/password is incorrect' do
      VCR.use_cassette('redvine_error') do
        expect { client.connect(email: 'fake_email@someplace.net', password: 'nope1nope2nope3', skip_exception: true) }.to_not raise_error
      end
    end

  end

  context '(when authenticated)' do

    let(:client) { setup_client() }

    describe '.search' do

      it 'should respond to a search method' do
        VCR.use_cassette('redvine') do
          expect(client).to respond_to(:search)
        end
      end

      it 'should throw an error without a tag' do
        VCR.use_cassette('redvine') do
          expect{ client.search() }.to raise_error(ArgumentError)
        end
      end

      it 'should return a result set with videoUrls when searching for a common keyword' do
        VCR.use_cassette('redvine', :record => :new_episodes) do
          vines = client.search('cat')
          expect(vines.count).to be > 1
          expect(vines.first.videoUrl).to be_an_instance_of(String)
          expect(vines.last.videoUrl).to be_an_instance_of(String)
        end
      end

      it 'should return a second page of results' do
        VCR.use_cassette('redvine', :record => :new_episodes) do
          vines = client.search('cat')
          vinesp2 = client.search('cat', :page => 2)
          expect(vines).to_not equal(vinesp2)
          expect(vines.first.videoUrl).to_not equal(vinesp2.first.videoUrl)
        end
      end

    end

    describe '.search_posts' do

      it 'should respond to a search_posts method' do
        VCR.use_cassette('redvine') do
          expect(client).to respond_to(:search_posts)
        end
      end

      it 'should throw an error without a query' do
        VCR.use_cassette('redvine') do
          expect{ client.search_posts() }.to raise_error(ArgumentError)
        end
      end

      it 'should return a result set with videoUrls when searching for a common keyword' do
        VCR.use_cassette('redvine', :record => :new_episodes) do
          vines = client.search_posts('cat')
          expect(vines.count).to be > 1
          expect(vines.first.videoUrl).to be_an_instance_of(String)
          expect(vines.last.videoUrl).to be_an_instance_of(String)
        end
      end

      it 'should return a second page of results' do
        VCR.use_cassette('redvine', :record => :new_episodes) do
          vines = client.search_posts('cat')
          vinesp2 = client.search_posts('cat', :page => 2)
          expect(vines).to_not equal(vinesp2)
          expect(vines.first.videoUrl).to_not equal(vinesp2.first.videoUrl)
        end
      end

    end

    describe '.popular' do

      it 'should respond to a popular method' do
        expect(client).to respond_to(:popular)
      end

      it 'should return a set of results with VideoUrls' do
        VCR.use_cassette('redvine', :record => :new_episodes) do
          vines = client.popular
          expect(vines.count).to be > 1
          expect(vines.first.videoUrl).to be_an_instance_of(String)
        end
      end

      it 'should return a second page of results' do
        VCR.use_cassette('redvine', :record => :new_episodes) do
          vines = client.popular
          vinesp2 = client.popular(:page => 2)
          expect(vines).to_not equal(vinesp2)
          expect(vines.first.videoUrl).to_not equal(vinesp2.first.videoUrl)
        end
      end

    end


    describe '.promoted' do

      it 'should respond to a promoted method' do
        expect(client).to respond_to(:promoted)
      end

      it 'should return a set of results with VideoUrls' do
        VCR.use_cassette('redvine', :record => :new_episodes) do
          vines = client.promoted
          expect(vines.count).to be > 1
          expect(vines.first.videoUrl).to be_an_instance_of(String)
        end
      end

      it 'should return a second page of results' do
        VCR.use_cassette('redvine', :record => :new_episodes) do
          vines = client.promoted
          vinesp2 = client.promoted(:page => 2)
          expect(vines).to_not equal(vinesp2)
          expect(vines.first.videoUrl).to_not equal(vinesp2.first.videoUrl)
        end
      end

    end

    describe '.timeline' do

      it 'should respond to a timeline method' do
        expect(client).to respond_to(:timeline)
      end

      it 'should return a set of results with VideoUrls' do
        VCR.use_cassette('redvine', :record => :new_episodes) do
          vines = client.timeline
          expect(vines.count).to be > 1
          expect(vines.first.videoUrl).to be_an_instance_of(String)
        end
      end

      it 'should return a second page of results' do
        VCR.use_cassette('redvine', :record => :new_episodes) do
          vines = client.timeline()
          vinesp2 = client.timeline(:page => 2)
          expect(vines).to_not equal(vinesp2)
          expect(vines.first.videoUrl).to_not equal(vinesp2.first.videoUrl)
        end
      end

    end

    describe '.user_profile' do

      it 'should respond to a user_profile method' do
        expect(client).to respond_to(:user_profile)
      end

      it 'should throw an error without a user id' do
        expect { client.user_profile() }.to raise_error(ArgumentError)
      end

      it 'should not throw an error when user id is numeric' do
        VCR.use_cassette('redvine', :record => :new_episodes) do
          expect { client.user_profile(914021455983943680) }.not_to raise_error
        end
      end

      it 'should return a user profile for the authenticated user' do
        VCR.use_cassette('redvine', :record => :new_episodes) do
          profile = client.user_profile(client.user_id.to_s)
          expect(profile.userId).not_to be_nil
          expect(profile.username).to be_an_instance_of(String)
          expect(profile.avatarUrl).to be_an_instance_of(String)
        end
      end

      it 'should return a user profile given a valid user id' do
        VCR.use_cassette('redvine', :record => :new_episodes) do
          profile = client.user_profile('914021455983943680')
          expect(profile.userId).not_to be_nil
          expect(profile.username).to be_an_instance_of(String)
          expect(profile.avatarUrl).to be_an_instance_of(String)
        end
      end

    end

    describe '.user_likes' do

      it 'should respond to a user_likes method' do
        expect(client).to respond_to(:user_likes)
      end

      it 'should throw an error without a user id' do
        expect { client.user_likes() }.to raise_error(ArgumentError)
      end

      it 'should not throw an error when user id is numeric' do
        VCR.use_cassette('redvine', :record => :new_episodes) do
          expect { client.user_likes(914021455983943680) }.not_to raise_error
        end
      end

      it 'should return a set of results with VideoUrls given a user id with some likes' do
        VCR.use_cassette('redvine', :record => :new_episodes) do
          vines = client.user_likes('1104962313704103936')
          expect(vines.count).to be > 0
          expect(vines.first.videoUrl).to be_an_instance_of(String)
        end
      end

    end

    describe '.user_timeline' do

      it 'should respond to a user_timeline method' do
        expect(client).to respond_to(:user_timeline)
      end

      it 'should throw an error without a user id' do
        expect { client.user_timeline() }.to raise_error(ArgumentError)
      end

      it 'should not throw an error when user id is numeric' do
        VCR.use_cassette('redvine', :record => :new_episodes) do
          expect { client.user_timeline(914021455983943680) }.not_to raise_error
        end
      end

      it 'should return a set of results with VideoUrls given a valid user id' do
        VCR.use_cassette('redvine', :record => :new_episodes) do
          vines = client.user_timeline('914021455983943680')
          expect(vines.count).to be > 1
          expect(vines.first.videoUrl).to be_an_instance_of(String)
        end
      end

      it 'should return a second page of results' do
        VCR.use_cassette('redvine', :record => :new_episodes) do
          vines = client.user_timeline('914021455983943680')
          vinesp2 = client.user_timeline('914021455983943680', :page => 2)
          expect(vines).to_not equal(vinesp2)
          expect(vines.first.videoUrl).to_not equal(vinesp2.first.videoUrl)
        end
      end

      it 'should not break if an error is returned from Vine' do
        VCR.use_cassette('redvine', :record => :new_episodes) do
          vines = client.user_timeline('965095451261071400')
          expect(vines.success).to eq(false)
          vines = client.user_timeline('XXX')
          expect(vines.success).to eq(false)
        end
      end

    end

    describe '.following' do

      it 'should respond to a following method' do
        expect(client).to respond_to(:following)
      end

      it 'should throw an error without a user id' do
        expect { client.following() }.to raise_error(ArgumentError)
      end

      it 'should not throw an error when user id is numeric' do
        VCR.use_cassette('redvine', :record => :new_episodes) do
          expect { client.following(914021455983943680) }.not_to raise_error
        end
      end

      it 'should return a set of results with avatar and username given a valid user id' do
        VCR.use_cassette('redvine', :record => :new_episodes) do
          users = client.following('914021455983943680')
          expect(users.count).to be > 1
          expect(users.first.username).to be_an_instance_of(String)
          expect(users.first.avatarUrl).to be_an_instance_of(String)
        end
      end

      it 'should return a second page of results' do
        VCR.use_cassette('redvine', :record => :new_episodes) do
          users = client.following('914021455983943680')
          usersp2 = client.following('914021455983943680', :page => 2)
          expect(users).to_not equal(usersp2)
          expect(users.first.avatarUrl).to_not equal(usersp2.first.avatarUrl)
        end
      end

      it 'should not break if an error is returned from Vine' do
        VCR.use_cassette('redvine', :record => :new_episodes) do
          users = client.following('965095451261071400')
          expect(users.success).to eq(false)
          users = client.following('XXX')
          expect(users.success).to eq(false)
        end
      end

    end

    describe '.followers' do

      it 'should respond to a followers method' do
        expect(client).to respond_to(:followers)
      end

      it 'should throw an error without a user id' do
        expect { client.followers() }.to raise_error(ArgumentError)
      end

      it 'should not throw an error when user id is numeric' do
        VCR.use_cassette('redvine', :record => :new_episodes) do
          expect { client.followers(914021455983943680) }.not_to raise_error
        end
      end

      it 'should return a set of results with avatar and username given a valid user id' do
        VCR.use_cassette('redvine', :record => :new_episodes) do
          users = client.followers('914021455983943680')
          expect(users.count).to be > 1
          expect(users.first.username).to be_an_instance_of(String)
          expect(users.first.avatarUrl).to be_an_instance_of(String)
        end
      end

      it 'should return a second page of results' do
        VCR.use_cassette('redvine', :record => :new_episodes) do
          users = client.followers('914021455983943680')
          usersp2 = client.followers('914021455983943680', :page => 2)
          expect(users).to_not equal(usersp2)
          expect(users.first.avatarUrl).to_not equal(usersp2.first.avatarUrl)
        end
      end

      it 'should not break if an error is returned from Vine' do
        VCR.use_cassette('redvine', :record => :new_episodes) do
          users = client.followers('965095451261071400')
          expect(users.success).to eq(false)
          users = client.followers('XXX')
          expect(users.success).to eq(false)
        end
      end

    end

    describe '.single_post' do

      it 'should respond to a single_post method' do
        expect(client).to respond_to(:single_post)
      end

      it 'should require a post id as an argument' do
        expect { client.single_post() }.to raise_error(ArgumentError)
      end

      it 'should not throw an error when post id is numeric' do
        VCR.use_cassette('redvine', :record => :new_episodes) do
          expect { client.single_post(1038918228849876992) }.not_to raise_error
        end
      end

      it 'should return a single media result with a valid post id' do
        VCR.use_cassette('redvine', :record => :new_episodes) do
          vine = client.single_post('1038918228849876992')
          expect(vine.videoUrl).to be_an_instance_of(String)
        end
      end

      it 'should not break if no post exists with that id' do
        VCR.use_cassette('redvine', :record => :new_episodes) do
          vine = client.single_post('397923400300')
          expect(vine.success).to eq(false)
          vine2 = client.single_post('XXX')
          expect(vine2.success).to eq(false)
        end
      end
    end

  end

end
