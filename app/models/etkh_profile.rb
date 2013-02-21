class EtkhProfile < ActiveRecord::Base
  belongs_to :user

  attr_accessible :background,
                  :career_plans,
                  :confirmed,
                  :inspiration,
                  :interesting_fact,
                  :occupation,
                  :organisation,
                  :organisation_role,
                  :doing_good_inspiring,
                  :doing_good_research,
                  :doing_good_philanthropy,
                  :doing_good_prophilanthropy,
                  :doing_good_innovating,
                  :doing_good_improving,
                  :public_profile,
                  :skills_knowledge_share,
                  :skills_knowledge_learn,
                  :causes_comment,
                  :profile_option_cause_ids,
                  :activities_comment,
                  :profile_option_activity_ids,
                  :donation_percentage,
                  :donation_percentage_optout

  # now we can access @etkh_profile.name etc.
  delegate :name, :name=, 
           :location, :location=,
           :to => :user

  scope :newest, order("created_at DESC")

  has_and_belongs_to_many :profile_option_causes
  has_and_belongs_to_many :profile_option_activities


  # public method for profile completeness score
  def get_profile_completeness
    calculate_completeness_score
  end

  # public method which returns a suggestion for what the user
  # should do to improve their profile
  def get_suggested_profile_addition
    ## in order of precedence

    # add location
    if self.location.nil?
      "Add your current location"
    # add organisation
    elsif self.organisation.nil?
      "Add your current organisation"
    # profile photo
    elsif !self.user.avatar?
      "Upload a photo to your profile so members "
    # add background info if none already
    elsif !self.background?
      "Fill out your 'background and interests' and tell us why you are here"
    # sync their account with linkedin ?

    # add causes
    elsif !self.profile_option_causes.any?
      "Let us know what you care about and add causes to your profile"
    # add high impact activities
    elsif !self.profile_option_activities.any?
      "What are you doing to make a difference? Add your high impact activities to your profile"
    # improve background if not long
    elsif self.background.length < BACKGROUND_MAX_LEN
      "Tell us more about yourself by adding to your 'background and interests'"
    # donation tracking ?
    end
  end

  def get_background_snippet(maxLength)
    # returns a maximum of a whole paragraph or maxLength in characters
    snippet_max = self.background[0..maxLength]
    snippet_max
  end

  private

  ### Profile completeness ###
  # define percentages for composition of profile score
  PROFILE_PIC = 25
  INFO_LOCATION = 5
  INFO_ORGANISATION = 5
  BACKGOUND = 15
  EXPERIENCE = 5
  DONATION_TRACKING = 5
  SKILLS = 5
  HIGH_IMPACT_ACTIVITIES = 10
  CAUSES = 10
  LINKEDIN_PROFILE = 15

  # length of 'background and interests' section after which no more points 
  BACKGROUND_MAX_LEN = 1000

  def calculate_completeness_score
    score = 0

    # profile photo
    score += PROFILE_PIC if self.user.avatar?

    # basic information
    score += INFO_LOCATION if self.location
    score += INFO_ORGANISATION if self.organisation

    # background and interests
    # completeness score depends on how long the entry is
    # the score varies linearly until a max cut-off is reached
    if self.background
      len = self.background.length
      if len >= BACKGROUND_MAX_LEN
        score += BACKGOUND
      else
        float = BACKGOUND.to_f / BACKGROUND_MAX_LEN.to_f * len.to_f
        score += float.to_i
      end
    end

    # high impact activities
    score += HIGH_IMPACT_ACTIVITIES if self.profile_option_activities.any?

    # causes
    score += CAUSES if self.profile_option_causes.any?

    # donation tracking ?
    # experience
    # skills
    # linkedin profile ?

    return score
  end
end
