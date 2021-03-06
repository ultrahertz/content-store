require 'rails_helper'

describe "content item write API", :type => :request do
  before :each do
    @data = {
      "base_path" => "/vat-rates",
      "content_id" => SecureRandom.uuid,
      "title" => "VAT rates",
      "description" => "Current VAT rates",
      "format" => "answer",
      "need_ids" => ["100123", "100124"],
      "locale" => "en",
      "public_updated_at" => "2014-05-14T13:00:06Z",
      "update_type" => "major",
      "publishing_app" => "publisher",
      "rendering_app" => "frontend",
      "details" => {
        "body" => "<p>Some body text</p>\n",
      },
      "routes" => [
        { "path" => "/vat-rates", "type" => 'exact' }
      ],
    }
  end

  describe "creating a new content item" do
    it "responds with a CREATED status" do
      put_json "/content/vat-rates", @data
      expect(response.status).to eq(201)
    end

    it "creates the content item" do
      put_json "/content/vat-rates", @data
      item = ContentItem.where(:base_path => "/vat-rates").first
      expect(item).to be
      expect(item.title).to eq("VAT rates")
      expect(item.description).to eq("Current VAT rates")
      expect(item.format).to eq("answer")
      expect(item.need_ids).to eq(["100123", "100124"])
      expect(item.locale).to eq("en")
      expect(item.public_updated_at).to match_datetime("2014-05-14T13:00:06Z")
      expect(item.updated_at).to be_within(10.seconds).of(Time.zone.now)
      expect(item.details).to eq({"body" => "<p>Some body text</p>\n"})
    end

    it "responds with an empty JSON document in the body" do
      put_json "/content/vat-rates", @data
      expect(response.body).to eq('{}')
    end

    it "registers routes for the content item" do
      put_json "/content/vat-rates", @data
      assert_routes_registered("frontend", [['/vat-rates', 'exact']])
    end

    context "with no content ID" do
      before :each do
        @data.delete "content_id"
      end

      it "responds with a CREATED status" do
        put_json "/content/vat-rates", @data
        expect(response.status).to eq(201)
      end
    end
  end

  describe "creating a non-English content item" do
    it "creates the content item" do
      foreign_data = @data.merge("title" => "Taux de TVA",
                                 "locale" => 'fr',
                                 "base_path" => "/vat-rates.fr",
                                 "routes" => [
                                   { "path" => "/vat-rates.fr", "type" => 'exact' }
                                ])

      put_json "/content/vat-rates.fr", foreign_data
      item = ContentItem.where(:base_path => "/vat-rates.fr").first
      expect(item).to be
      expect(item.title).to eq("Taux de TVA")
      expect(item.locale).to eq("fr")
    end
  end

  context 'updating an existing content item' do
    before(:each) do
      Timecop.travel(30.minutes.ago) do
        @item = create(:content_item,
                     :title => "Original title",
                     :base_path => "/vat-rates",
                     :need_ids => ["100321"],
                     :public_updated_at => Time.zone.parse("2014-03-12T14:53:54Z"),
                     :details => {"foo" => "bar"}
                    )
      end
      WebMock::RequestRegistry.instance.reset! # Clear out any requests made by factory creation.
    end

    it "responds with an OK status" do
      put_json "/content/vat-rates", @data
      expect(response.status).to eq(200)
    end

    it "updates the content item" do
      put_json "/content/vat-rates", @data
      @item.reload
      expect(@item.title).to eq("VAT rates")
      expect(@item.need_ids).to eq(["100123", "100124"])
      expect(@item.public_updated_at).to eq(Time.zone.parse("2014-05-14T13:00:06Z"))
      expect(@item.updated_at).to be_within(10.seconds).of(Time.zone.now)
      expect(@item.details).to eq({"body" => "<p>Some body text</p>\n"})
    end

    it "updates routes for the content item" do
      put_json "/content/vat-rates", @data
      assert_routes_registered("frontend", [['/vat-rates', 'exact']])
    end
  end

  context "given invalid JSON data" do
    before(:each) do
      put "/content/foo", "I'm not json", "CONTENT_TYPE" => "application/json"
    end

    it "returns a Bad Request status" do
      expect(response.status).to eq(400)
    end
  end

  context "given a partial update" do
    before(:each) do
      @item = create(:content_item, :base_path => "/vat-rates")

      put_json "/content/vat-rates", @data.except("title")
    end

    it "returns a Unprocessable Entity status" do
      expect(response.status).to eq(422)
    end

    it "includes validation error messages in the response" do
      data = JSON.parse(response.body)
      expect(data["errors"]).to eq({"title" => ["can't be blank"]})
    end
  end

  context "create with an invalid content item" do
    before(:each) do
      @data["title"] = ""
      put_json "/content/vat-rates", @data
    end

    it "returns a Unprocessable Entity status" do
      expect(response.status).to eq(422)
    end

    it "includes validation error messages in the response" do
      data = JSON.parse(response.body)
      expect(data["errors"]).to eq({"title" => ["can't be blank"]})
    end
  end

  context "create with extra fields in the input" do
    before :each do
      @data["foo"] = "bar"
      @data["bar"] = "baz"
      put_json "/content/vat-rates", @data
    end

    it "rejects the update" do
      expect(response.status).to eq(422)
    end

    it "includes an error message" do
      data = JSON.parse(response.body)
      expect(data["errors"]).to eq({"base" => ["unrecognised field(s) foo, bar in input"]})
    end
  end

  context "create with value of incorrect type" do
    before :each do
      @data["routes"] = 12
      put_json "/content/vat-rates", @data
    end

    it "rejects the update" do
      expect(response.status).to eq(422)
    end

    it "includes an error message" do
      data = JSON.parse(response.body)
      expected_error_message = Mongoid::Errors::InvalidValue.new(Array, @data['routes'].class).message
      expect(data["errors"]).to eq({"base" => [expected_error_message]})
    end
  end

  context "copes with non-ASCII paths" do
    let(:path) { URI.encode('/news/בוט לאינד') }
    before :each do
      @data['base_path'] = path
      @data['routes'][0]['path'] = path
    end

    it "should accept a request with non-ASCII path" do
      put_json "/content/#{path}", @data
      expect(response.status).to eq(201)
    end

    it "creates the item with encoded base_path" do
      put_json "/content/#{path}", @data
      item = ContentItem.where(:base_path => path).first
      expect(item).to be
      expect(item.base_path).to eq(path)
    end
  end
end
