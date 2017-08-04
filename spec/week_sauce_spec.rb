require 'spec_helper'
require 'active_support/all'

describe WeekSauce do
  
  let(:days) do
    # Sunday => 0 similar to Time#wday
    %w(sunday monday tuesday wednesday thursday friday saturday).map(&:to_sym)
  end
  
  # The maximum value of the bitmask (2**7 - 1)
  let(:max) { 127 }
  
  describe "initializer" do
    it "defaults to zero/blank" do
      expect(WeekSauce.new.to_i).to eq 0
      expect(WeekSauce.new(nil).to_i).to eq 0
    end
    
    it "accepts valid numbers" do
      expect(WeekSauce.new(0).to_i).to   eq 0
      expect(WeekSauce.new(64).to_i).to  eq 64
      expect(WeekSauce.new(max).to_i).to eq max
    end
    
    it "clamps input" do
      expect(WeekSauce.new(-100).to_i).to eq 0
      expect(WeekSauce.new(2**9).to_i).to eq max
    end
  end
  
  describe "interrogation" do
    context "with no days set" do
      let(:week) { WeekSauce.new }
      it "returns correct values" do
        expect(week.blank?).to  be_truthy
        expect(week.any?).to    be_falsey
        expect(week.many?).to   be_falsey
        expect(week.one?).to    be_falsey
        expect(week.all?).to    be_falsey
        days.each do |day|
          expect(week.send("#{day.to_s}?")).to be_falsey
        end
      end
    end
    
    context "with only one day set" do
      let(:week) { WeekSauce.new(16) } # Thursday
      it "returns correct values" do
        expect(week.blank?).to  be_falsey
        expect(week.any?).to    be_truthy
        expect(week.many?).to   be_falsey
        expect(week.one?).to    be_truthy
        expect(week.all?).to    be_falsey
        days.each do |day|
          expect(week.send("#{day.to_s}?")).to eq (day == :thursday)
        end
      end
    end
    
    context "with more than one day set" do
      let(:week) { WeekSauce.new(31) } # Sunday-Thursday
      it "returns correct values" do
        expect(week.blank?).to  be_falsey
        expect(week.any?).to    be_truthy
        expect(week.many?).to   be_truthy
        expect(week.one?).to    be_falsey
        expect(week.all?).to    be_falsey
        days[0..4].each do |day|
          expect(week.send("#{day.to_s}?")).to be_truthy
        end
        days[5..6].each do |day|
          expect(week.send("#{day.to_s}?")).to be_falsey
        end
      end
    end
    
    context "with all days set" do
      let(:week) { WeekSauce.new(max) }
      it "returns correct values" do
        expect(week.blank?).to  be_falsey
        expect(week.any?).to    be_truthy
        expect(week.many?).to   be_truthy
        expect(week.one?).to    be_falsey
        expect(week.all?).to    be_truthy
        days.each do |day|
          expect(week.send("#{day.to_s}?")).to be_truthy
        end
      end
    end
  end
  
  describe "writing" do
    describe "using bracket syntax" do
      let(:week) { WeekSauce.new }
      it "works with integers" do
        week[0] = true
        week[0] = true # repeated on purpose to expose bitwise XOR errors
        expect(week.to_i).to eq 1
        week[6] = true
        expect(week.to_i).to eq 65
      end
      
      it "works with integer strings" do
        week["0"] = true
        expect(week.to_i).to eq 1
        week["5"] = true
        expect(week.to_i).to eq 33
      end
      
      it "works with day-name strings (upper- and lowercase)" do
        week["sunday"] = true
        expect(week.to_i).to eq 1
        week["THURSDAY"] = true
        expect(week.to_i).to eq 17
        week["MoNdAy"] = true
        expect(week.to_i).to eq 19
      end
      
      it "ignores out-of-bounds integers" do
        week[-1] = true
        expect(week.to_i).to eq 0
        week[7] = true
        expect(week.to_i).to eq 0
      end
      
      it "works with day-name symbols" do
        week[:sunday] = true
        expect(week.to_i).to eq 1
        week[:wednesday] = true
        expect(week.to_i).to eq 9
      end
      
      it "ignores non-sensical symbols" do
        week[:foo] = true
        expect(week.to_i).to eq 0
      end
      
      it "works with Time and TimeWithZone objects" do
        week[Time.now] = true
        expect(week.to_i).to eq 2**Time.now.wday
        
        Time.zone = ActiveSupport::TimeZone["Copenhagen"]
        time = Time.zone.now
        week[time] = true
        expect(week.to_i).to eq 2**time.wday
      end
      
      it "works with Date and DateTime objects" do
        date = Date.today
        week[date] = true
        expect(week.to_i).to eq 2**date.wday
        
        date = DateTime.now
        week[date] = true
        expect(week.to_i).to eq 2**date.wday
      end
      
      it "ignores unhandled argument types" do
        week["string"] = true
        expect(week.to_i).to eq 0
      end
    end
    
    it "works with day-name setters" do
      week = WeekSauce.new
      week.sunday = true
      expect(week.to_i).to eq 1
      week.saturday = true
      expect(week.to_i).to eq 65
    end
    
    describe "using the set method" do
      it "sets multiple days" do
        week = WeekSauce.new(42)
        week.set 0, :tuesday, :thursday, 6
        expect(week.all?).to be_truthy
      end
    end
    
    describe "using the set! method" do
      it "sets multiple days, and only those days" do
        week = WeekSauce.new(42)
        week.set! 0, :tuesday
        expect(week.to_i).to eq 5
      end
      
      it "returns self" do
        week = WeekSauce.new(42)
        expect(week.set!(:tuesday)).to be(week)
      end
    end
    
    describe "using the unset method" do
      it "unsets multiple days" do
        week = WeekSauce.new(42)
        week.unset 1, :wednesday, :friday
        expect(week.blank?).to be_truthy
      end
    end
    
    describe "using the unset! method" do
      it "unsets multiple days, and only those days" do
        week = WeekSauce.new(42)
        week.unset! :monday, :wednesday, 4, :friday, 6
        expect(week.to_i).to eq 5
      end
      
      it "returns self" do
        week = WeekSauce.new(42)
        expect(week.unset!(:monday)).to be(week)
      end
    end
  end
  
  describe "reading" do
    describe "using bracket syntax" do
      let(:week) { WeekSauce.new(42) } # Monday, Wednesday, Friday
      
      it "works with integers" do
        expect(week[0]).to be_falsey
        expect(week[1]).to be_truthy
        expect(week[2]).to be_falsey
        expect(week[3]).to be_truthy
        expect(week[4]).to be_falsey
        expect(week[5]).to be_truthy
        expect(week[6]).to be_falsey
      end
      
      it "returns nil for out-of-bounds integers" do
        expect(week[-1]).to be_nil
        expect(week[7]).to be_nil
      end
      
      it "works with integer strings" do
        expect(week["0"]).to be_falsey
        expect(week["1"]).to be_truthy
        expect(week["2"]).to be_falsey
        expect(week["3"]).to be_truthy
        expect(week["4"]).to be_falsey
        expect(week["5"]).to be_truthy
        expect(week["6"]).to be_falsey
      end
      
      it "works with day-name strings (upper- and lowercase)" do
        expect(week["sunday"]).to be_falsey
        expect(week["MONDAY"]).to be_truthy
        expect(week["tuesday"]).to be_falsey
        expect(week["WeDnEsDaY"]).to be_truthy
        expect(week["thursday"]).to be_falsey
        expect(week["friDAY"]).to be_truthy
        expect(week["SATURday"]).to be_falsey
      end
      
      it "returns nil for non-sensical strings" do
        expect(week["bacon"]).to be_nil
        expect(week["monkey"]).to be_nil
      end
      
      it "works with day-name symbols" do
        expect(week[:sunday]).to be_falsey
        expect(week[:monday]).to be_truthy
        expect(week[:tuesday]).to be_falsey
        expect(week[:wednesday]).to be_truthy
        expect(week[:thursday]).to be_falsey
        expect(week[:friday]).to be_truthy
        expect(week[:saturday]).to be_falsey
      end
      
      it "returns nil for non-sensical symbols" do
        expect(week[:foo]).to be_nil
      end
      
      it "works with Time and TimeWithZone objects" do
        time = Time.now
        time = time + (3 - time.wday).days # set to Wednesday
        expect(week[time]).to be_truthy
        time = time + 1.day # set to Thursday
        expect(week[time]).to be_falsey
        
        Time.zone = ActiveSupport::TimeZone["Copenhagen"]
        time = Time.zone.now
        time = time + (3 - time.wday).days
        expect(week[time]).to be_truthy
        time = time + 1.day # set to Thursday
        expect(week[time]).to be_falsey
      end
      
      it "works with Date and DateTime objects" do
        date = Date.today
        date = date + (3 - date.wday).days # set to Wednesday
        expect(week[date]).to be_truthy
        date = date + 1.day # set to Thursday
        expect(week[date]).to be_falsey
        
        date = DateTime.now
        date = date + (3 - date.wday).days # set to Wednesday
        expect(week[date]).to be_truthy
        date = date + 1.day # set to Thursday
        expect(week[date]).to be_falsey
      end
      
      it "returns nil for unhandled argument types" do
        expect(week["string"]).to be_nil
      end
    end
    
    it "works with day-name getters" do
      week = WeekSauce.new(42)
      expect(week.sunday).to    be_falsey
      expect(week.monday).to    be_truthy
      expect(week.tuesday).to   be_falsey
      expect(week.wednesday).to be_truthy
      expect(week.thursday).to  be_falsey
      expect(week.friday).to    be_truthy
      expect(week.saturday).to  be_falsey
    end
  end
  
  describe "blank! method" do
    it "clears the instance" do
      week = WeekSauce.new(max)
      week.blank!
      expect(week.to_i).to eq 0
    end
    
    it "returns self" do
      week = WeekSauce.new
      expect(week.blank!).to be(week)
    end
  end
  
  describe "all! method" do
    it "sets all bits" do
      week = WeekSauce.new
      week.all!
      expect(week.to_i).to eq max
    end
    
    it "returns self" do
      week = WeekSauce.new
      expect(week.all!).to be(week)
    end
  end
  
  describe "utilities" do
    describe "to_a" do
      it "returns an array" do
        expect(WeekSauce.new(42).to_a).to include(:monday, :wednesday, :friday)
        expect(WeekSauce.new.to_a).to eq([])
      end
    end
    
    describe "to_hash" do
      it "to_hash returns a hash" do
        expect(WeekSauce.new(42).to_hash).to  eq({
          sunday:    false,
          monday:    true,
          tuesday:   false,
          wednesday: true,
          thursday:  false,
          friday:    true,
          saturday:  false
        })
      end
    end
    
    describe "dup" do
      let(:week) { WeekSauce.new(rand(max+1)) }
      
      it "dups to a new instance" do
        expect(week.dup.to_i).to eq week.to_i
        expect(week.dup).to_not be(week)
      end
    end
    
    describe "inspect" do
      it "lists bitmask & days" do
        week = WeekSauce.new(42)
        expect(week.inspect).to eq "42: Monday, Wednesday, Friday"
      end
      
      it "returns a simple message if no days have been set" do
        week = WeekSauce.new
        expect(week.inspect).to eq "0: No days set"
      end
      
      it "returns a simple message if all days have been set" do
        week = WeekSauce.new.all!
        expect(week.inspect).to eq "127: All days set"
      end
    end
    
    describe "count" do
      it "returns the number of days set" do
        week = WeekSauce.new
        expect(week.count).to eq 0
        expect(week.all!.count).to eq 7
        expect(week.set!(0, 2, 5).count).to eq 3
      end
    end
  end
  
  describe "comparison" do
    let(:week) { WeekSauce.new(42) }
    
    it "works with fixnums" do
      expect(week).to     eq 42
      expect(week).to_not eq 43
    end
    
    it "works with other instances" do
      expect(week).to     eq WeekSauce.new(42)
      expect(week).to_not eq WeekSauce.new
    end
  end
  
  describe "date calculation" do
    describe "next_date" do
      let(:week) { WeekSauce.new(2**3) } # Wednesday
      
      it "finds next date from today if not argument is passed" do
        date = Date.today
        offset = 3 - date.wday
        offset += 7 if offset < 0
        expect(week.next_date).to eq date + offset.days
      end
      
      it "finds next date from a given day" do
        date = Time.parse "2013-04-01" # April fool's (also a happens to be a Monday)
        expect(week.next_date(date)).to eq date.to_date + 2
      end
      
      it "returns a duplicate of the from argument if it matches" do
        week = WeekSauce.new(3) # Monday
        date = Date.parse "2013-04-01"
        result = week.next_date(date)
        expect(result).to eq date
        expect(result).to_not be(date)
      end
      
      it "returns nil if the week's blank" do
        expect(WeekSauce.new.next_date).to be_nil
      end
    end
    
    describe "dates_in" do
      it "returns an array of dates in a given range" do
        week = WeekSauce.new
        starts = Date.today
        ends   = starts + 3.weeks
        week[starts] = true
        dates = week.dates_in(starts..ends)
        expect(dates.length).to eq 4
        expect(dates.first).to eq starts
        expect(dates.last).to eq ends
      end
      
      it "returns an empty array if the week's blank" do
        week = WeekSauce.new
        starts = Date.today
        ends   = starts + 3.weeks
        expect(week.dates_in(starts...ends).empty?).to be_truthy
      end
    end
  end
  
  describe "serialization" do
    describe "load" do
      it "loads from a string" do
        week = WeekSauce.load("127")
        expect(week.to_i).to eq 127
      end
      
      it "clamps value" do
        expect(WeekSauce.load("1027").to_i).to eq 127
        expect(WeekSauce.load("-127").to_i).to eq 0
      end
      
      it "absorbs conversion errors" do
        expect(WeekSauce.load([]).to_i).to eq 0
      end
    end
    
    describe "dump" do
      it "dumps to a string" do
        week = WeekSauce.new(42)
        expect(WeekSauce.dump(week)).to eq "42"
      end
      
      it "defaults to outputting zero" do
        expect(WeekSauce.dump(123)).to eq "0"
      end
    end
  end
  
end
